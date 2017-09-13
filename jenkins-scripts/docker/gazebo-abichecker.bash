#!/bin/bash -x

# Knowing Script dir beware of symlink
[[ -L ${0} ]] && SCRIPT_DIR=$(readlink ${0}) || SCRIPT_DIR=${0}
SCRIPT_DIR="${SCRIPT_DIR%/*}"

if [[ -z ${ARCH} ]]; then
  echo "ARCH variable not set!"
  exit 1
fi

if [[ -z ${DISTRO} ]]; then
  echo "DISTRO variable not set!"
  exit 1
fi

. ${SCRIPT_DIR}/lib/_gazebo_version_hook.bash

export ABI_JOB_SOFTWARE_NAME="gazebo"
export ABI_JOB_REPOS="stable"
export ABI_JOB_PKG_DEPENDENCIES_VAR_NAME="GAZEBO_BASE_DEPENDENCIES"
if [[ $GAZEBO_MAJOR_VERSION -lt 8 ]]; then
  export ABI_JOB_CMAKE_PARAMS="-DENABLE_TESTS_COMPILATION:BOOL=False"
fi
export ABI_JOB_IGNORE_HEADERS="gazebo/GIMPACT gazebo/opcode gazebo/test"
export ABI_JOB_IGNORE_HEADERS_FULL_PATH="/usr/include/simbody/ /usr/include/x86_64-linux-gnu/qt5/"

. ${SCRIPT_DIR}/lib/generic-abi-base.bash
