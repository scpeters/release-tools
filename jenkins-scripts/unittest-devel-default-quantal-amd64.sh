#!/bin/bash -x

# Knowing Script dir beware of symlink
[[ -L ${0} ]] && SCRIPT_DIR=$(readlink ${0}) || SCRIPT_DIR=${0}
SCRIPT_DIR="${SCRIPT_DIR%/*}"


# TODO: remove this when all unit tests are real unit test not needed GUI
export DISPLAY=$(ps aux | grep "X :" | grep -v grep | awk '{ print $12 }')

export DISTRO=quantal
export ROS_DISTRO=groovy

. ${SCRIPT_DIR}/lib/unittest-base-default.bash
