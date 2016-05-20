#!/bin/bash -x

# Variables to use:
#  - SOFTWARE_DIR [mandatory]: name of directory containing sources
#  - NPM_JOB_PRE_BUILDING_HOOK [optional]
#  - NPM_JOB_POST_BUILDING_HOOK [optional]

# Knowing Script dir beware of symlink
[[ -L ${0} ]] && SCRIPT_DIR=$(readlink ${0}) || SCRIPT_DIR=${0}
SCRIPT_DIR="${SCRIPT_DIR%/*}"

. ${SCRIPT_DIR}/lib/generic-npm-base.bash
