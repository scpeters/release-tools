#!/bin/bash -x

# Knowing Script dir beware of symlink
[[ -L ${0} ]] && SCRIPT_DIR=$(readlink ${0}) || SCRIPT_DIR=${0}
SCRIPT_DIR="${SCRIPT_DIR%/*}"

export DISTRO=precise
export ROS_DISTRO=fuerte
export PKG_VERSION="stable"

ARENAS_HEAVY_TEST_SUITE=true
. ${SCRIPT_DIR}/lib/arenas-nightly.bash
