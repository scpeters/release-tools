#!/bin/bash -x


DOCKER_JOB_NAME="simbody_debbuild"
. ${SCRIPT_DIR}/lib/boilerplate_prepare.sh

cat > build.sh << DELIM
###################################################
# Make project-specific changes here
#
#!/usr/bin/env bash
set -ex

# Install deb-building tools
apt-get install -y pbuilder fakeroot debootstrap devscripts dh-make ubuntu-dev-tools debhelper wget git

# Step 0: create/update distro-specific pbuilder environment
pbuilder-dist $DISTRO $ARCH create /etc/apt/trusted.gpg --debootstrapopts --keyring=/etc/apt/trusted.gpg

# Step 0: Clean up
rm -rf $WORKSPACE/build
mkdir -p $WORKSPACE/build
cd $WORKSPACE/build

# Clean from workspace all package related files
rm -fr $WORKSPACE/"$PACKAGE"_*

# Step 1: Get the source (nightly builds or tarball)
rm -fr $WORKSPACE/simbody
git clone https://github.com/simbody/simbody.git $WORKSPACE/simbody
cd $WORKSPACE/simbody
git checkout Simbody-${VERSION}

# Use current distro
sed -i -e 's:precise:$DISTRO:g' debian/changelog
# Use current release version
sed -i -e 's:-1~:-$RELEASE_VERSION~:' debian/changelog
# Bug in saucy doxygen makes the job hangs
if [ $DISTRO = 'saucy' ]; then
    sed -i -e '/.*dh_auto_build.*/d' debian/rules
fi
if [ $DISTRO = 'trusty' ]; then
# Patch for https://github.com/simbody/simbody/issues/157
  sed -i -e 's:CONFIGURE_ARGS=:CONFIGURE_ARGS=-DCMAKE_BUILD_TYPE=RelWithDebInfo:' debian/rules
fi

# Step 5: use debuild to create source package
echo | dh_make -s --createorig -p ${PACKAGE}_${VERSION} || true

debuild -S -uc -us --source-option=--include-binaries -j${MAKE_JOBS}

export DEB_BUILD_OPTIONS="parallel=$MAKE_JOBS"
# Step 6: use pbuilder-dist to create binary package(s)
pbuilder-dist $DISTRO $ARCH build ../*.dsc -j${MAKE_JOBS}

mkdir -p $WORKSPACE/pkgs
rm -fr $WORKSPACE/pkgs/*

PKGS=\`find .. -name '*.deb' || true\`

FOUND_PKG=0
for pkg in \${PKGS}; do
    echo "found \$pkg"
    # Check for correctly generated packages size > 3Kb
    test -z \$(find \$pkg -size +3k) && echo "WARNING: empty package?" 
    # && exit 1
    cp \${pkg} $WORKSPACE/pkgs
    FOUND_PKG=1
done
# check at least one upload
test \$FOUND_PKG -eq 1 || exit 1
DELIM

#
# Make project-specific changes here
###################################################

cat > Dockerfile << DELIM_DOCKER
#######################################################
# Docker file to run build.sh

FROM osrf/ubuntu_armhf:${DISTRO}
MAINTAINER Jose Luis Rivero <jrivero@osrfoundation.org>

# If host is running squid-deb-proxy on port 8000, populate /etc/apt/apt.conf.d/30proxy
# By default, squid-deb-proxy 403s unknown sources, so apt shouldn't proxy ppa.launchpad.net
RUN route -n | awk '/^0.0.0.0/ {print \$2}' > /tmp/host_ip.txt
RUN echo "HEAD /" | nc \$(cat /tmp/host_ip.txt) 8000 | grep squid-deb-proxy \
  && (echo "Acquire::http::Proxy \"http://\$(cat /tmp/host_ip.txt):8000\";" > /etc/apt/apt.conf.d/30proxy) \
  && (echo "Acquire::http::Proxy::ppa.launchpad.net DIRECT;" >> /etc/apt/apt.conf.d/30proxy) \
  || echo "No squid-deb-proxy detected on docker host"

# Map the workspace into the container
RUN mkdir -p ${WORKSPACE}
# automatic invalidation of the cache if day is different
RUN echo "${TODAY_STR}"
RUN apt-get update
RUN apt-get install -y fakeroot debootstrap devscripts equivs dh-make ubuntu-dev-tools mercurial debhelper wget pkg-kde-tools bash-completion
ADD build.sh build.sh
RUN chmod +x build.sh
DELIM_DOCKER

sudo rm -fr ${WORKSPACE}/pkgs
sudo mkdir -p ${WORKSPACE}/pkgs

if [[ $ARCH == armhf ]]; then
  sudo docker pull osrf/ubuntu_armhf
  sudo docker build -t ${DOCKER_TAG} .
else
  echo "Architecture still unsupported"
  exit 1
fi

sudo docker run  \
            --cidfile=${CIDFILE} \
            -v ${WORKSPACE}/pkgs:${WORKSPACE}/pkgs \
            -t ${DOCKER_TAG} \
            /bin/bash build.sh

CID=$(cat ${CIDFILE})

sudo docker stop ${CID} || true
sudo docker rm ${CID} || true
