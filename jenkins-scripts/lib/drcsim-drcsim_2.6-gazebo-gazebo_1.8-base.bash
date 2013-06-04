#!/bin/bash -x
set -e

# Use always DISPLAY in drcsim project
export DISPLAY=$(ps aux | grep "X :" | grep -v grep | awk '{ print $12 }')

. ${SCRIPT_DIR}/lib/boilerplate_prepare.sh

# Be able to pass different gazebo branches to testing
if [ -z ${GAZEBO_BRANCH} ]; then
    GAZEBO_BRANCH="gazebo_1.8"
fi

export GZ_CMAKE_BUILD_TYPE="-DCMAKE_BUILD_TYPE=RelWithDebInfo"

cat > build.sh << DELIM
###################################################
# Make project-specific changes here
#
set -ex

# try to get core dumps
ulimit -c unlimited

# get ROS repo's key
apt-get install -y wget
sh -c 'echo "deb http://packages.ros.org/ros/ubuntu ${DISTRO} main" > /etc/apt/sources.list.d/ros-latest.list'
wget http://packages.ros.org/ros.key -O - | apt-key add -
# Also get drc repo's key, to be used in getting Gazebo
sh -c 'echo "deb http://packages.osrfoundation.org/drc/ubuntu ${DISTRO} main" > /etc/apt/sources.list.d/drc-latest.list'
wget http://packages.osrfoundation.org/drc.key -O - | apt-key add -
apt-get update

# Step 1: install everything you need
apt-get install -y mercurial ca-certificates ${BASE_DEPENDENCIES} ${GAZEBO_BASE_DEPENDENCIES} ${DRCSIM_BASE_DEPENDENCIES} sandia-hand-nightly osrf-common-nightly

# Optional stuff. Check for graphic card support
if ${GRAPHIC_CARD_FOUND}; then
    apt-get install -y ${GRAPHIC_CARD_PKG}
fi

# Normal cmake routine for Gazebo
rm -fr $WORKSPACE/gazebo
hg clone https://bitbucket.org/osrf/gazebo -b ${GAZEBO_BRANCH} $WORKSPACE/gazebo
cd $WORKSPACE/gazebo
hg up ${GAZEBO_BRANCH}

rm -rf $WORKSPACE/gazebo/build $WORKSPACE/gazebo/install
mkdir -p $WORKSPACE/gazebo/build $WORKSPACE/gazebo/install
cd $WORKSPACE/gazebo/build
CMAKE_PREFIX_PATH=/opt/ros/${ROS_DISTRO} cmake ${GZ_CMAKE_BUILD_TYPE} -DCMAKE_INSTALL_PREFIX=/usr $WORKSPACE/gazebo
make -j${MAKE_JOBS}
make install
. /usr/share/gazebo-1.*/setup.sh

# Step 3: configure and build drcim
if [ $DISTRO = quantal ]; then
    rosdep init && rosdep update
fi
# Normal cmake routine
. /opt/ros/${ROS_DISTRO}/setup.sh
. /usr/share/gazebo/setup.sh
rm -rf $WORKSPACE/build $WORKSPACE/install
mkdir -p $WORKSPACE/build $WORKSPACE/install
cd $WORKSPACE/build
cmake ${GZ_CMAKE_BUILD_TYPE} -DCMAKE_INSTALL_PREFIX=$WORKSPACE/install $WORKSPACE/drcsim
make -j${MAKE_JOBS}
make install
SHELL=/bin/sh . $WORKSPACE/install/share/drcsim/setup.sh
export PATH="\$PATH:$WORKSPACE/install/bin/"
ROS_TEST_RESULTS_DIR=$WORKSPACE/build/test_results make test ARGS="-VV" || true
ROS_TEST_RESULTS_DIR=$WORKSPACE/build/test_results rosrun rosunit clean_junit_xml.py
# Try to get core files out of chroot
mkdir $WORKSPACE/build/core_dumped
if [ -d /var/lib/jenkins/.ros ]; then
cp -a /var/lib/jenkins/.ros/ $WORKSPACE/build/core_dumped/
fi
if [ -d /root/.ros ]; then
cp -a /root/.ros/ $WORKSPACE/build/core_dumped/
fi
DELIM

# Make project-specific changes here
###################################################

sudo pbuilder  --execute \
    --bindmounts $WORKSPACE \
    --basetgz $basetgz \
    -- build.sh

#[[ -d $WORKSPACE/build/core_dumped ]] && find $WORKSPACE/build/core_dumped -name *core* -exec sudo mv {} /var/lib/jenkins/core_$RANDOM \;
