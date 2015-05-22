#!/bin/bash -x

echo '# BEGIN SECTION: setup the testing enviroment'
USE_OSRF_REPO=true
USE_GPU_DOCKER=true
DOCKER_JOB_NAME="handsim_ci"
. ${SCRIPT_DIR}/lib/boilerplate_prepare.sh
echo '# END SECTION'

cat > build.sh << DELIM
###################################################
# Make project-specific changes here
#
set -ex

# Not really needed?
# export DISPLAY=${DISPLAY}

echo '# BEGIN SECTION: configuring'
mkdir -p $WORKSPACE/build
cd $WORKSPACE/build
cmake $WORKSPACE/handsim
echo '# END SECTION'

echo '# BEGIN SECTION: compiling'
make -j${MAKE_JOBS}
echo '# END SECTION'

echo '# BEGIN SECTION: installing'
make install
echo '# END SECTION'

echo '# BEGIN SECTION: running tests'
mkdir -p \$HOME
make test ARGS="-VV" || true
echo '# END SECTION'

echo '# BEGIN SECTION: cppcheck'
cd $WORKSPACE/handsim
sh tools/code_check.sh -xmldir $WORKSPACE/build/cppcheck_results || true

# Step 5. Need to clean build/ directory so disk space is under control
# Move cppcheck and test results out of build
# Copy the results
mv $WORKSPACE/build/cppcheck_results $WORKSPACE/cppcheck_results
mv $WORKSPACE/build/test_results $WORKSPACE/test_results
echo '# END SECTION'
DELIM

SOFTWARE_DIR="handsim"
DEPENDENCY_PKGS="${HANDSIM_DEPENDENCIES}"
. ${SCRIPT_DIR}/lib/docker_generate_dockerfile.bash
. ${SCRIPT_DIR}/lib/docker_run.bash
