#!/bin/bash -x

# Knowing Script dir beware of symlink
[[ -L ${0} ]] && SCRIPT_DIR=$(readlink ${0}) || SCRIPT_DIR=${0}
SCRIPT_DIR="${SCRIPT_DIR%/*}"

export GPU_SUPPORT_NEEDED=true
export DISTRO=trusty

# By default true
export DART_FROM_PKGS=${DART_FROM_PKGS:=true}
export DART_COMPILE_FROM_SOURCE=${DART_COMPILE_FROM_SOURCE:=false}
export DART_COMPILE_FROM_SOURCE_BRANCH=${DART_COMPILE_FROM_SOURCE_BRANCH:=master}

. ${SCRIPT_DIR}/lib/gazebo-base-default.bash
