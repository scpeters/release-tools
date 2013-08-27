#!/bin/bash -x

#stop on error
set -e

if [[ -z ${TEST_TYPE} ]]; then
    echo "No test type specified"
    exit 1
fi

if [[ ${TEST_TYPE} == "INTEGRATION" ]]; then
    ARTIFACT_FILE="integration_tests.tar.bz2"
    EXTRA_PACKAGES="${EXTRA_PACKAGES} ${GAZEBO_TEST_INTEGRATION_DEPENDENCIES}"
elif [[ ${TEST_TYPE} == "PERFORMANCE" ]]; then
    ARTIFACT_FILE="performance_tests.tar.bz2"
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
apt-get install -y ${BASE_DEPENDENCIES} ${GAZEBO_BASE_DEPENDENCIES} ${GAZEBO_EXTRA_DEPENDENCIES} ${GAZEBO_TEST_INTEGRATION_DEPENDENCIES} ${EXTRA_PACKAGES}

# Optional stuff. Check for graphic card support
if ${GRAPHIC_CARD_FOUND}; then
    apt-get install -y ${GRAPHIC_CARD_PKG}
    # Check to be sure version of kernel graphic card support is the same.
    # It will kill DRI otherwise
    CHROOT_GRAPHIC_CARD_PKG_VERSION=\$(dpkg -l | grep "^ii.*${GRAPHIC_CARD_PKG}\ " | awk '{ print \$3 }' | sed 's:-.*::')
    if [ "\${CHROOT_GRAPHIC_CARD_PKG_VERSION}" != "${GRAPHIC_CARD_PKG_VERSION}" ]; then
       echo "Package ${GRAPHIC_CARD_PKG} has different version in chroot and host system. Maybe you need to update your host" 
       exit 1
    fi
fi

# Install gazebo: binary version and source code to run tests from there
tar -xjf ${WORKSPACE}/gazebo.tar.bz2 -C /
tar -xjf ${WORKSPACE}/source.tar.bz2 -C ${WORKSPACE}
# Install the binaries of test suite
tar -xjf ${WORKSPACE}/${ARTIFACT_FILE} -C ${WORKSPACE}/$SOFTWARE/build
cd ${WORKSPACE}/${SOFTWARE}/build

# Fake build directory
mkdir -p /var/lib/jenkins/workspace/gazebo-default-refactor_main-${DISTRO}-amd64
ln -s $WORKSPACE/gazebo /var/lib/jenkins/workspace/gazebo-default-refactor_main-${DISTRO}-amd64/gazebo
. /usr/share/gazebo/setup.sh

cat /usr/share/gazebo/cmake/gazebo-config.cmake
cat /usr/lib/pkgconfig/gazebo.pc

make test ARGS="-VV -R ${TEST_TYPE}_*" || true

DELIM

# Make project-specific changes here
###################################################

sudo pbuilder  --execute \
    --bindmounts $WORKSPACE \
    --basetgz $basetgz \
    -- build.sh

