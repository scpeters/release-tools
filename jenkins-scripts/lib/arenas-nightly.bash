#!/bin/bash -x
set -e

export DISPLAY=$(ps aux | grep "X :" | grep -v grep | awk '{ print $12 }')
. ${SCRIPT_DIR}/lib/boilerplate_prepare.sh

ARENAS_TEST_SUITE_STR="-DLIGHT_TEST_SUITE=1"

if [[ ${ARENAS_HEAVY_TEST_SUITE} ]] ; then
    ARENAS_TEST_SUITE_STR="-DHEAVY_TEST_SUITE=1"
fi
if [[ ${ARENAS_PARANOID_TEST_SUITE} ]] ; then
    ARENAS_TEST_SUITE_STR="-DPARANOID_TEST_SUITE=1"
fi

cat > build.sh << DELIM
###################################################
# Make project-specific changes here
#
set -ex

# get ROS repo's key
apt-get install -y wget
sh -c 'echo "deb http://packages.ros.org/ros/ubuntu ${DISTRO} main" > /etc/apt/sources.list.d/ros-latest.list'
wget --no-check-certificate http://packages.ros.org/ros.key -O - | apt-key add -
# Also get drc repo's key, to be used in getting Gazebo
sh -c 'echo "deb http://packages.osrfoundation.org/drc/ubuntu ${DISTRO} main" > /etc/apt/sources.list.d/drc-latest.list'
wget --no-check-certificate http://packages.osrfoundation.org/drc.key -O - | apt-key add -
apt-get update

# Step 1: install everything you need
# Install drcsim's and gazebo nightly

# Inject gazebo log_segfault_alt
apt-get install -y wget
wget https://www.dropbox.com/s/0do8h1w7kw98kyq/gazebo-nightly_1.8.3%7Eexphg20130603ra11495281488-1%7Eprecise_amd64.deb
dpkg -i gazebo-nightly_*.deb
wget https://www.dropbox.com/s/54u843jib73fok7/gazebo-nightly-dbg_1.8.3%7Eexphg20130603ra11495281488-1%7Eprecise_amd64.deb 
dpkg -i gazebo-nightly-dbg_*.deb

apt-get install -y drcsim-nightly ${DRCSIM_BASE_DEPENDENCIES}

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
cmake $WORKSPACE/vrc_arenas -DCMAKE_INSTALL_PREFIX=/usr ${ARENAS_TEST_SUITE_STR}
make -j${MAKE_JOBS} install
. /usr/share/vrc_arenas/setup.sh

ROS_TEST_RESULTS_DIR=$WORKSPACE/build/test_results make test ARGS="-VV" || true
ROS_TEST_RESULTS_DIR=$WORKSPACE/build/test_results rosrun rosunit clean_junit_xml.py
if [ -d /root/.ros ]; then
cp -a /root/.ros/ $WORKSPACE/build/core_dumped/
fi
if [ -d /var/lib/jenkins/.ros ]; then
cp -a /var/lib/jenkins/.ros/ $WORKSPACE/build/core_dumped/
fi
DELIM

# Make project-specific changes here
###################################################

sudo pbuilder  --execute \
    --bindmounts $WORKSPACE \
    --basetgz $basetgz \
    -- build.sh

find $WORKSPACE/build/core_dumped -name *core* -exec mv {} ${HOME}/core_$RANDOM \;
