#!/bin/bash -x

# Knowing Script dir beware of symlink
[[ -L ${0} ]] && SCRIPT_DIR=$(readlink ${0}) || SCRIPT_DIR=${0}
SCRIPT_DIR="${SCRIPT_DIR%/*}"

export DISTRO=quantal
export ROS_DISTRO=groovy

export SOFTWARE_UNDER_TEST=drcsim
export GAZEBO_DEB_PACKAGE=gazebo-nightly

. ${SCRIPT_DIR}/lib/install-checker-nightly.bash
