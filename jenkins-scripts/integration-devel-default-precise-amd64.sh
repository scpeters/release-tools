#!/bin/bash -x

# Knowing Script dir beware of symlink
[[ -L ${0} ]] && SCRIPT_DIR=$(readlink ${0}) || SCRIPT_DIR=${0}
SCRIPT_DIR="${SCRIPT_DIR%/*}"


# TODO: remove this when all unit tests are real unit test not needed GUI
export DISPLAY=$(ps aux | grep "X :" | grep -v grep | awk '{ print $12 }')

export DISTRO=precise
export ROS_DISTRO=fuerte

. ${SCRIPT_DIR}/lib/integrationtest-base-default.bash
