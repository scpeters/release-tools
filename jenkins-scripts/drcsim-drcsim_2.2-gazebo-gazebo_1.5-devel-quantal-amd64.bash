#!/bin/bash -x

# Knowing Script dir beware of symlink
[[ -L ${0} ]] && SCRIPT_DIR=$(readlink ${0}) || SCRIPT_DIR=${0}
SCRIPT_DIR="${SCRIPT_DIR%/*}"

export DISTRO=quantal
export ROS_DISTRO=groovy

. ${SCRIPT_DIR}/lib/drcsim-drcsim_2.2-gazebo-gazebo_1.5-base.bash
