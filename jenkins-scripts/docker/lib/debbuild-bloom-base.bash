#!/bin/bash -x

NIGHTLY_MODE=false
if [ "${VERSION}" = "nightly" ]; then
   NIGHTLY_MODE=true
fi

# Do not use the subprocess_reaper in debbuild. Seems not as needed as in
# testing jobs and seems to be slow at the end of jenkins jobs
export ENABLE_REAPER=false

PACKAGE_UNDERSCORE_NAME=${PACKAGE//-/_}

. ${SCRIPT_DIR}/lib/boilerplate_prepare.sh

cat > build.sh << DELIM
###################################################
# Make project-specific changes here
#
#!/usr/bin/env bash
set -ex

cd $WORKSPACE/build

echo '# BEGIN SECTION: clone bloom ROS release repo'
rm -rf /tmp/$PACKAGE-release
git clone ${UPSTREAM_RELEASE_REPO} /tmp/$PACKAGE-release
cd /tmp/$PACKAGE-release

FULL_VERSION=$VERSION-$RELEASE_VERSION
FULL_DEBIAN_BRANCH_NAME=ros-$ROS_DISTRO-$PACKAGE\_\$FULL_VERSION\_$DISTRO

git checkout release/$ROS_DISTRO/$PACKAGE_UNDERSCORE_NAME/\$FULL_VERSION
git checkout debian/\$FULL_DEBIAN_BRANCH_NAME
echo '# END SECTION'

echo '# BEGIN SECTION: create the orig/source package'
echo | dh_make -s --createorig -p ros-$ROS_DISTRO-${PACKAGE}_${VERSION} || true
ls ../*
debuild --no-tgz-check -uc -us -S --source-option=--include-binaries
echo '# END SECTION'

echo '# BEGIN SECTION: install build dependencies'
dpkg -l | grep ros
cat debian/control
DEBIAN_FRONTEND=noninteractive mk-build-deps -i -r -t 'apt-get -y' debian/control 
mkdir -p $WORKSPACE/pkgs && cp *.deb $WORKSPACE/pkgs
echo '# END SECTION'

echo '# BEGIN SECTION: running rosdep'
if [ -f /usr/bin/rosdep ]; then
  rosdep init
fi
echo '# END SECTION'

echo '# BEGIN SECTION: create deb packages'
debuild --no-tgz-check -uc -us --source-option=--include-binaries -j${MAKE_JOBS}
echo '# END SECTION'

# Set proper package names
PKG_NAME=ros-${ROS_DISTRO}-${PACKAGE}_${VERSION}-${RELEASE_VERSION}${DISTRO}_${ARCH}.deb

mkdir -p $WORKSPACE/pkgs
rm -fr $WORKSPACE/pkgs/*

PKGS=\`find /var/lib/jenkins/pbuilder/*_result* -name *.deb || true\`

FOUND_PKG=0
for pkg in \${PKGS}; do
    echo "found \$pkg"
    cp \${pkg} $WORKSPACE/pkgs
    FOUND_PKG=1
done
# check at least one upload
test \$FOUND_PKG -eq 1 || exit 1
DELIM

#
# Make project-specific changes here
###################################################

USE_OSRF_REPO=true
USE_ROS_REPO=true
DEPENDENCY_PKGS="devscripts \
		 ubuntu-dev-tools \
		 debhelper \
		 wget \
		 ca-certificates \
		 equivs \
		 dh-make \
		 mercurial \
		 git \
		 cdbs"

. ${SCRIPT_DIR}/lib/docker_generate_dockerfile.bash
. ${SCRIPT_DIR}/lib/docker_run.bash
