#!/bin/bash -x

# TODO: either call directly the script where I copied this from or figure out what should change

# Knowing Script dir beware of symlink
[[ -L ${0} ]] && SCRIPT_DIR=$(readlink ${0}) || SCRIPT_DIR=${0}
SCRIPT_DIR="${SCRIPT_DIR%/*}"

export DISTRO=trusty
export REPO_DIRECTORY="haptix_comm"
export PKG_DEPENDENCIES_VAR_NAME="HAPTIX_COMM_DEPENDENCIES"

set -e

. ${SCRIPT_DIR}/lib/boilerplate_prepare.sh

eval PROJECT_DEPENDECIES=\$${PKG_DEPENDENCIES_VAR_NAME}

cat > build.sh << DELIM
###################################################
# Make project-specific changes here
#
set -ex

# OSRF repository to get zmq
apt-get install -y wget
sh -c 'echo "deb http://packages.osrfoundation.org/drc/ubuntu ${DISTRO} main" > /etc/apt/sources.list.d/drc-latest.list'
wget http://packages.osrfoundation.org/drc.key -O - | apt-key add -

# Step 1: install everything you need
apt-get update
apt-get install -y ${BASE_DEPENDENCIES} ${PROJECT_DEPENDECIES}

# Step 2: configure and build
rm -rf $WORKSPACE/build
mkdir -p $WORKSPACE/build
cd $WORKSPACE/build
cmake $WORKSPACE/${REPO_DIRECTORY}
make -j${MAKE_JOBS}
make install
make test ARGS="-VV" || true

# Step 3: code check
cd $WORKSPACE/${REPO_DIRECTORY}
sh tools/code_check.sh -xmldir $WORKSPACE/build/cppcheck_results || true
cat $WORKSPACE/build/cppcheck_results/*.xml
DELIM


# Extract the version out of CMakeLists
PROJECT_VERSION=`\
  grep 'set.*PROJECT_MAJOR_VERSION ' ${WORKSPACE}/CMakeLists.txt | \
  tr -d 'a-zA-Z _()'`.`\
  grep 'set.*PROJECT_MINOR_VERSION ' ${WORKSPACE}/CMakeLists.txt | \
  tr -d 'a-zA-Z _()'`.`\
  grep 'set.*PROJECT_PATCH_VERSION ' ${WORKSPACE}/CMakeLists.txt | \
  tr -d 'a-zA-Z _()'`

# Check if the node was configured to use s3cmd
# This is done by running s3cmd --configure
if [ ! -f "${HOME}/.s3cfg" ]; then
    echo "No $HOME/.s3cfg file found. Please config the software first in your system using s3cmd --config"
    exit 1
fi

# Make documentation if not build
if [ ! -f "$WORKSPACE/build/doxygen/html/index.html" ]; then
  cd $WORKSPACE/build
  make doc
  if [ ! -f "$WORKSPACE/build/doxygen/html/index.html" ]; then
    echo "Documentation not present. Install doxygen, and run `make doc` in the build directory"
    exit 1
  fi
fi

# Dry run for now
s3cmd sync $WORKSPACE/build/doxygen/html/* s3://osrf-distributions/haptix/api/$PROJECT_VERSION/ --dry-run -v

#echo -n "Upload (Y/n)? "
#read ans

#if [ "$ans" = "n" ] || [ "$ans" = "N" ]; then
#  exit 1
#else

#s3cmd sync @CMAKE_BINARY_DIR@/doxygen/html/* s3://osrf-distributions/haptix/api/@PROJECT_VERSION_FULL@/ -v
#fi
