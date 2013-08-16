#!/bin/bash -x

#stop on error
set -e

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

# Install gazebo: binary version and source code to run tests from there
tar -xvjf ${WORKSPACE}/gazebo.tar.bz2 -C /--strip 1 
tar -xjf ${WORKSPACE}/source.tar.bz2 -C ${WORKSPACE}
# Install the binaries of unit test suite
tar -xjf ${WORKSPACE}/unit_tests.tar.bz2 -C ${WORKSPACE}/$SOFTWARE/build
cd ${WORKSPACE}/${SOFTWARE}/build
# Need to run cmake again to fix system paths
rm CMakeCache.txt 
cmake ..
make test ARGS="-VV" || true

# . /usr/share/gazebo/setup.sh
DELIM

# Make project-specific changes here
###################################################

sudo pbuilder  --execute \
    --bindmounts $WORKSPACE \
    --basetgz $basetgz \
    -- build.sh

