#!/bin/bash -x

# TODO: either call directly the script where I copied this from or figure out what should change

# Knowing Script dir beware of symlink
[[ -L ${0} ]] && SCRIPT_DIR=$(readlink ${0}) || SCRIPT_DIR=${0}
SCRIPT_DIR="${SCRIPT_DIR%/*}"

export DISTRO=trusty
export REPO_DIRECTORY="haptix_comm"
export PKG_DEPENDENCIES_VAR_NAME="HAPTIX_COMM_DEPENDENCIES"

. ${SCRIPT_DIR}/lib/generic-job.bash

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
    echo "No $HOME/.s3cfg file found. Please config the software first in your system"
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
