#!/bin/bash -x

# Knowing Script dir beware of symlink
[[ -L ${0} ]] && SCRIPT_DIR=$(readlink ${0}) || SCRIPT_DIR=${0}
SCRIPT_DIR="${SCRIPT_DIR%/*}"

export DISTRO=precise
export ROS_DISTRO=fuerte

. ${SCRIPT_DIR}/lib/drcsim-drcsim_2.6-gazebo-gazebo_1.8-base.bash
