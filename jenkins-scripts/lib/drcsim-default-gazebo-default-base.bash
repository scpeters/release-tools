#!/bin/bash -x
set -e

# Use always DISPLAY in drcsim project
export DISPLAY=$(ps aux | grep "X :" | grep -v grep | awk '{ print $12 }')

. ${SCRIPT_DIR}/lib/boilerplate_prepare.sh

if [ -z ${GZ_BUILD_TYPE} ]; then
    GZ_CMAKE_BUILD_TYPE=
else
    GZ_CMAKE_BUILD_TYPE="-DCMAKE_BUILD_TYPE=${GZ_BUILD_TYPE}"
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

# Install mercurial and drcsim's and gazebo Build-Depends
apt-get install -y mercurial ca-certificates ${BASE_DEPENDENCIES} ${GAZEBO_BASE_DEPENDENCIES} ${GAZEBO_EXTRA_DEPENDENCIES} ${DRCSIM_BASE_DEPENDENCIES}

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

. /opt/ros/${ROS_DISTRO}/setup.sh

if [ $DISTRO = quantal ]; then
    rosdep init 
    # Hack for not failing when github is down
    update_done=false
    seconds_waiting=0
    while (! \$update_done); do
      rosdep update && update_done=true
      sleep 1
      seconds_waiting=$((seconds_waiting+1))
      [ \$seconds_waiting -gt 60 ] && exit 1
    done
fi

# 1. Normal cmake routine for osrf-common
rm -fr $WORKSPACE/osrf-common
hg clone https://bitbucket.org/osrf/osrf-common $WORKSPACE/osrf-common

cd $WORKSPACE/osrf-common
export ROS_PACKAGE_PATH=\$PWD:\$ROS_PACKAGE_PATH
rm -rf $WORKSPACE/osrf-common/build
mkdir -p $WORKSPACE/osrf-common/build
cd $WORKSPACE/osrf-common/build
CMAKE_PREFIX_PATH=/opt/ros/${ROS_DISTRO} cmake -DCMAKE_INSTALL_PREFIX=/usr $WORKSPACE/osrf-common
make -j3
make install

# Normal cmake routine for sandia-hand
rm -fr $WORKSPACE/sandia-hand
hg clone https://bitbucket.org/osrf/sandia-hand $WORKSPACE/sandia-hand

cd $WORKSPACE/sandia-hand
export ROS_PACKAGE_PATH=\$PWD:/usr/share/osrf-common-1.0/ros:\$ROS_PACKAGE_PATH
rm -rf $WORKSPACE/sandia-hand/build
mkdir -p $WORKSPACE/sandia-hand/build
cd $WORKSPACE/sandia-hand/build
CMAKE_PREFIX_PATH=/opt/ros/${ROS_DISTRO} cmake -DCMAKE_INSTALL_PREFIX=/usr $WORKSPACE/sandia-hand
make -j3
make install

# Normal cmake routine for Gazebo
rm -fr $WORKSPACE/gazebo
hg clone https://bitbucket.org/osrf/gazebo $WORKSPACE/gazebo

rm -rf $WORKSPACE/gazebo/build $WORKSPACE/gazebo/install
mkdir -p $WORKSPACE/gazebo/build $WORKSPACE/gazebo/install
cd $WORKSPACE/gazebo/build
CMAKE_PREFIX_PATH=/opt/ros/${ROS_DISTRO} cmake ${GZ_CMAKE_BUILD_TYPE} -DCMAKE_INSTALL_PREFIX=/usr $WORKSPACE/gazebo
make -j1
make install
. /usr/share/gazebo-1.*/setup.sh

# Normal cmake routine
. /opt/ros/${ROS_DISTRO}/setup.sh
. /usr/share/gazebo/setup.sh
rm -rf $WORKSPACE/build $WORKSPACE/install
mkdir -p $WORKSPACE/build $WORKSPACE/install
cd $WORKSPACE/build
cmake ${GZ_CMAKE_BUILD_TYPE} -DCMAKE_INSTALL_PREFIX=$WORKSPACE/install $WORKSPACE/drcsim
make -j3
make install
SHELL=/bin/sh . $WORKSPACE/install/share/drcsim/setup.sh
export PATH="\$PATH:$WORKSPACE/install/bin/"
ROS_TEST_RESULTS_DIR=$WORKSPACE/build/test_results make test ARGS="-VV" || true
ROS_TEST_RESULTS_DIR=$WORKSPACE/build/test_results rosrun rosunit clean_junit_xml.py
DELIM

# Make project-specific changes here
###################################################

sudo pbuilder  --execute \
    --bindmounts $WORKSPACE \
    --basetgz $basetgz \
    -- build.sh
