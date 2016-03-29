#!/bin/bash -x

# Knowing Script dir beware of symlink
[[ -L ${0} ]] && SCRIPT_DIR=$(readlink ${0}) || SCRIPT_DIR=${0}
SCRIPT_DIR="${SCRIPT_DIR%/*}"

ARCH=amd64

DISTRO=xenial

# Can not use generic compilation since we host the DART instalation and some
# other logic based of every gazebo version
. ${SCRIPT_DIR}/lib/xenial-cmakee.bash
