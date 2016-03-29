#!/bin/bash -x

# Parameters
#  - GAZEBO_BASE_CMAKE_ARGS (optional) extra arguments to pass to cmake
#  - GAZEBO_BASE_TESTS_HOOK (optional) [default to run UNIT, INTEGRATION, REGRESSION, EXAMPLE]
#                           piece of code to run in the testing section

#stop on error
set -e

. ${SCRIPT_DIR}/lib/_gazebo_version_hook.bash

echo '# BEGIN SECTION: setup the testing enviroment'
# Define the name to be used in docker
DOCKER_JOB_NAME="gazebo_ci"
. ${SCRIPT_DIR}/lib/boilerplate_prepare.sh

# If Coverage build type was supplied in GAZEBO_BASE_CMAKE_ARGS, add lcov
# package.
if [[ ${GAZEBO_BASE_CMAKE_ARGS} != ${GAZEBO_BASE_CMAKE_ARGS/Coverage} ]]; then
  EXTRA_PACKAGES="${EXTRA_PACKAGES} lcov" 
fi

cat > build.sh << DELIM
###################################################
# Make project-specific changes here
#
set -ex
source ${TIMING_DIR}/_time_lib.sh ${WORKSPACE}

init_stopwatch COMPILATION_bootstrap
# Normal cmake routine for Gazebo
echo '# BEGIN SECTION: Gazebo configuration'
rm -rf $WORKSPACE/install
mkdir -p $WORKSPACE/install
cd $WORKSPACE/build
cmake ${GAZEBO_BASE_CMAKE_ARGS}      \\
    -DCMAKE_INSTALL_PREFIX=/usr      \\
    -DENABLE_SCREEN_TESTS:BOOL=False \\
  $WORKSPACE/gazebo
echo '# END SECTION'

echo '# BEGIN SECTION: Gazebo compilation'
make -j${MAKE_JOBS}
echo '# END SECTION'
init_stopwatch COMPILATION_bootstrap

init_stopwatch COMPILATION_pch
# Normal cmake routine for Gazebo
echo '# BEGIN SECTION: Gazebo configuration'
rm -rf $WORKSPACE/build
mkdir -p $WORKSPACE/build
cd $WORKSPACE/build
cmake ${GAZEBO_BASE_CMAKE_ARGS}      \\
    -DCMAKE_INSTALL_PREFIX=/usr      \\
    -DENABLE_SCREEN_TESTS:BOOL=False \\
    -DUSE_PCH=ON
  $WORKSPACE/gazebo
echo '# END SECTION'

echo '# BEGIN SECTION: Gazebo compilation'
make -j${MAKE_JOBS}
echo '# END SECTION'
init_stopwatch COMPILATION_pch

DELIM

USE_OSRF_REPO=true
SOFTWARE_DIR="gazebo"
DEPENDENCY_PKGS="${BASE_DEPENDENCIES} \
                 ${GAZEBO_BASE_DEPENDENCIES} \
		 ${GAZEBO_EXTRA_DEPENDENCIES} \
		 ${EXTRA_PACKAGES}"

. ${SCRIPT_DIR}/lib/docker_generate_dockerfile.bash
. ${SCRIPT_DIR}/lib/docker_run.bash
