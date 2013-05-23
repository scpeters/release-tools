#!/bin/bash -x
set -e

export DISPLAY=$(ps aux | grep "X :" | grep -v grep | awk '{ print $12 }')
. ${SCRIPT_DIR}/lib/boilerplate_prepare.sh

ARENAS_LIGHT_TEST_SUITE_STR="-DLIGHT_TEST_SUITE=1"

if ! ${ARENAS_LIGHT_TEST_SUITE} ; then
    ARENAS_LIGHT_TEST_SUITE_STR=""
fi
 
cat > build.sh << DELIM
###################################################
# Make project-specific changes here
#
set -ex

# get ROS repo's key
apt-get install -y wget
sh -c 'echo "deb http://packages.ros.org/ros/ubuntu ${DISTRO} main" > /etc/apt/sources.list.d/ros-latest.list'
wget http://packages.ros.org/ros.key -O - | apt-key add -
# Also get drc repo's key, to be used in getting Gazebo
sh -c 'echo "deb http://packages.osrfoundation.org/drc/ubuntu ${DISTRO} main" > /etc/apt/sources.list.d/drc-latest.list'
wget http://packages.osrfoundation.org/drc.key -O - | apt-key add -
apt-get update

# Step 1: install everything you need
# Install drcsim's and gazebo nightly
apt-get install -y drcsim-nightly

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

# Step 2: load all setup files available
. /opt/ros/${ROS_DISTRO}/setup.sh
. /usr/share/gazebo/setup.sh
SHELL=/bin/sh . /usr/share/drcsim/setup.sh

# Step 3: configure and build
rm -rf $WORKSPACE/build
mkdir -p $WORKSPACE/build
cd $WORKSPACE/build
cmake $WORKSPACE/vrc_arenas -DCMAKE_INSTALL_PREFIX=/usr ${ARENAS_LIGHT_TEST_SUITE_STR}
make install
. /usr/share/vrc_arenas/setup.sh

ROS_TEST_RESULTS_DIR=$WORKSPACE/build/test_results make test ARGS="-VV" || true
DELIM

# Make project-specific changes here
###################################################

sudo pbuilder  --execute \
    --bindmounts $WORKSPACE \
    --basetgz $basetgz \
    -- build.sh
