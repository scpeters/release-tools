#!/bin/bash -x
set -e

# Use always DISPLAY in drcsim project
export DISPLAY=$(ps aux | grep "X :" | grep -v grep | awk '{ print $12 }')

. ${SCRIPT_DIR}/lib/boilerplate_prepare.sh

# Be able to pass different gazebo branches to testing
if [ -z ${GAZEBO_BRANCH} ]; then
    GAZEBO_BRANCH="gazebo_1.8"
fi

if [ -z ${TEST_RUNS} ]; then
    TEST_RUNS=1
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
#apt-get update

# Step 1: install everything you need
#apt-get install -y drcsim-nightly

cat > foo.c <<- DELIM2
main;
DELIM2
gcc foo.c -o foo
./foo || true

echo $WORKSPACE/core_dumps
rmdir -fr $WORKSPACE/core_dumps
mkdir -p $WORKSPACE/core_dumps
find /var/lib/jenkins -name *core* -exec ls -lash {} \;
find /var/lib/jenkins -name *core* -exec cp {} $WORKSPACE/core_dumps/ \;
find /var/lib/jenkins -name *core* -exec ls -lash {} \;
find /var/lib/jenkins -name *core* -exec cp {} $WORKSPACE/core_dumps/ \;
DELIM

# Make project-specific changes here
###################################################

sudo pbuilder  --execute \
    --bindmounts $WORKSPACE \
    --basetgz $basetgz \
    -- build.sh

if [[ -d "$WORKSPACE/core_dumps" ]]; then 
find $WORKSPACE/core_dumps -name *core* -exec sudo mv {} /var/lib/jenkins/core_$RANDOM \;
fi
