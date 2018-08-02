#!/bin/bash -x

case ${DISTRO} in
  'kinetic')
    ROS_DISTRO=melodic
    GAZEBO_VERSION_FOR_ROS="9"
    ;;
  'bionic')
    # 9 is the default version in Bionic
    ROS_DISTRO=melodic
    USE_DEFAULT_GAZEBO_VERSION_FOR_ROS=true
    ;;
  *)
    echo "Unsupported DISTRO: ${DISTRO}"
    exit 1
esac

export GPU_SUPPORT_NEEDED=true

# Do not use the subprocess_reaper in debbuild. Seems not as needed as in
# testing jobs and seems to be slow at the end of jenkins jobs
export ENABLE_REAPER=false

DOCKER_JOB_NAME="subt_ci"
. ${SCRIPT_DIR}/lib/boilerplate_prepare.sh


export ROS_SETUP_POSTINSTALL_HOOK="""
echo '# BEGIN SECTION: smoke test'
wget -P /tmp/ https://bitbucket.org/osrf/gazebo_models/get/default.tar.gz
mkdir -p ~/.gazebo/models
tar -xvf /tmp/default.tar.gz -C ~/.gazebo/models --strip 1
rm /tmp/default.tar.gz

source ./devel/setup.bash

TEST_TIMEOUT=180
TEST_START=\$(date +%s)
timeout --preserve-status \$TEST_TIMEOUT roslaunch subt_gazebo lava_tube.launch extra_gazebo_args:=\"--verbose\"
TEST_END=\$(date +%s)
DIFF=\$(expr \$TEST_END - \$TEST_START)

if [ \$DIFF -lt \$TEST_TIMEOUT ]; then
  echo \"The test took less than \$TEST_TIMEOUT. Something bad happened.\"
  Typo
  exit 1
fi

echo 'Smoke testing completed successfully.'
echo '# END SECTION'
"""

# Generate the first part of the build.sh file for ROS
. ${SCRIPT_DIR}/lib/_ros_setup_buildsh.bash "subt"

# No gazebo package. Built it from gz11
# By now using gz11 for all subt builds
export NEEDS_GZ11_SUPPORT=true

. "${SCRIPT_DIR}/lib/_gz11_hook.bash"

if ${NEEDS_GZ11_SUPPORT}; then
  export OSRF_REPOS_TO_USE="${OSRF_REPOS_TO_USE} prerelease"
  export DEPENDENCY_PKGS="${SUBT_NO_GAZEBO_DEPENDENCIES}"
  export BUILD_IGN_CMAKE=true
  export BUILD_IGN_PLUGIN=true
  export BUILD_IGN_MATH=true
  export BUILD_IGN_MSGS=true
  export BUILD_IGN_TRANSPORT=true
  export BUILD_IGN_GUI=true
  export BUILD_IGN_RENDERING=true
  export BUILD_IGN_SENSORS=true
  export BUILD_SDFORMAT=true
  ################################################

  TODO: build gazebo and gazebo_ros_pkgs from source

  ################################################
else
  export OSRF_REPOS_TO_USE="stable"
  export DEPENDENCY_PKGS="${SUBT_DEPENDENCIES}"
fi

# ROS packages come from the mirror in the own subt repository
USE_ROS_REPO=true

. ${SCRIPT_DIR}/lib/docker_generate_dockerfile.bash
. ${SCRIPT_DIR}/lib/docker_run.bash
