#!/bin/bash -x

# Knowing Script dir beware of symlink
[[ -L ${0} ]] && SCRIPT_DIR=$(readlink ${0}) || SCRIPT_DIR=${0}
SCRIPT_DIR="${SCRIPT_DIR%/*}"

# TRI ROS Mirror common library
. ${SCRIPT_DIR}/lib/_ros_snapshots_mirror_lib.bash

# Isolated repo
export INSTALL_JOB_PKG="ros-indigo-desktop-full"
export INSTALL_JOB_REPOS=""
export USE_ROS_REPO=false

INSTALL_JOB_PREINSTALL_HOOK="""
# import the TRI ROS mirror

wget ${SNAP_REPO_URL}/repo.key -O - | apt-key add -
echo \"deb ${SNAP_REPO_URL}/ ${DISTRO} main\" >\\
                        /etc/apt/sources.list.d/ros_snapshots_mirror.list
sudo apt-get update
"""

# Need bc to proper testing and parsing the time
export DEPENDENCY_PKGS DEPENDENCY_PKGS="wget bc"

. ${SCRIPT_DIR}/../docker/lib/generic-install-base.bash
