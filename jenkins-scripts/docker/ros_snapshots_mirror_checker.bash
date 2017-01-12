#!/bin/bash -x

# Knowing Script dir beware of symlink
[[ -L ${0} ]] && SCRIPT_DIR=$(readlink ${0}) || SCRIPT_DIR=${0}
SCRIPT_DIR="${SCRIPT_DIR%/*}"

# TRI ROS Mirror common library
. ${SCRIPT_DIR}/lib/_ros_snapshots_mirror_lib.bash

parse_inrelease()
{
  local url=${1}

  date_str=$(curl -s ${url} | grep Date | sed 's/Date: //g')
  echo $(date -d "${date_str}" +%s)
}

ROS_INRELEASE="${ROS_REPO_URL}/dists/trusty/InRelease"
SNAP_INRELEASE="${SNAP_REPO_URL}/dists/trusty/InRelease"

ros_date=$(parse_inrelease ${ROS_INRELEASE})
snap_date=$(parse_inrelease ${SNAP_INRELEASE})

if [[ ${snap_date} < ${ros_date} ]]; then
  echo "Update needed!"
  echo "MARK_AS_UNSTABLE" 
fi
