#!/bin/bash -x

#stop on error
set -e

# Keep the option of default to not really send a build type and let our own gazebo cmake rules
# to decide what is the default mode.
if [ -z ${GZ_BUILD_TYPE} ]; then
    GZ_CMAKE_BUILD_TYPE=
else
    GZ_CMAKE_BUILD_TYPE="-DCMAKE_BUILD_TYPE=${GZ_BUILD_TYPE}"
fi

. ${SCRIPT_DIR}/lib/boilerplate_prepare.sh

cat > build.sh << DELIM
###################################################
# Make project-specific changes here
#
set -ex

# OSRF repository to get bullet
apt-get install -y wget
sh -c 'echo "deb http://packages.osrfoundation.org/drc/ubuntu ${DISTRO} main" > /etc/apt/sources.list.d/drc-latest.list'
wget http://packages.osrfoundation.org/drc.key -O - | apt-key add -
apt-get update

# Step 1: install everything you need

# Required stuff for Gazebo
apt-get install -y ${BASE_DEPENDENCIES} ${GAZEBO_BASE_DEPENDENCIES} ${GAZEBO_EXTRA_DEPENDENCIES} ${EXTRA_PACKAGES}

# Optional stuff. Check for graphic card support
if ${GRAPHIC_CARD_FOUND}; then
    apt-get install -y ${GRAPHIC_CARD_PKG}
    # Check to be sure version of kernel graphic card support is the same.
    # It will kill DRI otherwise
    CHROOT_GRAPHIC_CARD_PKG_VERSION=\$(dpkg -l | grep "^ii.*${GRAPHIC_CARD_PKG}\ " | awk '{ print \$3 }')
    if [ "\${CHROOT_GRAPHIC_CARD_PKG_VERSION}" != "${GRAPHIC_CARD_PKG_VERSION}" ]; then
       echo "Package ${GRAPHIC_CARD_PKG} has different version in chroot and host system. Maybe you need to update your host" 
       exit 1
    fi
fi

# Step 2: configure and build

# Normal cmake routine for Gazebo
rm -rf $WORKSPACE/gazebo/build $WORKSPACE/install
mkdir -p $WORKSPACE/gazebo/build $WORKSPACE/install
cd $WORKSPACE/gazebo/build
cmake .. ${GZ_CMAKE_BUILD_TYPE} -DCMAKE_INSTALL_PREFIX=$WORKSPACE/image

# Export package_source
rm -fr $WORKSPACE/artifacts/source_code/*
mkdir -p $WORKSPACE/artifacts/source_code/
cd $WORKSPACE
tar --exclude-vcs -jcf $WORKSPACE/artifacts/source_code/source.tar.bz2 gazebo/

# Compilation
rm -fr $WORKSPACE/artifacts/binaries
mkdir -p $WORKSPACE/artifacts/binaries
rm -fr $WORKSPACE/image
mkdir -p $WORKSPACE/image
cd $WORKSPACE/gazebo/build
make -j${MAKE_JOBS}
find . -type f -name "UNIT_*_TEST" | xargs tar -cvjf $WORKSPACE/artifacts/binaries/unit_tests.tar.bz2;
find . -type f -name "INTEGRATION_*" | xargs tar -cvjf $WORKSPACE/artifacts/binaries/integration_tests.tar.bz2;
find . -type f -name "PERFORMANCE_*" | xargs tar -cvjf $WORKSPACE/artifacts/binaries/performance_tests.tar.bz2;

# Installation
make install
cd $WORKSPACE/image
tar -jcf $WORKSPACE/artifacts/binaries/gazebo.tar.bz2 gazebo/

# . /usr/share/gazebo/setup.sh
# make test ARGS="-VV" || true
DELIM

# Make project-specific changes here
###################################################

sudo pbuilder  --execute \
    --bindmounts $WORKSPACE \
    --basetgz $basetgz \
    -- build.sh

