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
# Workaround to issue:
# https://bitbucket.org/osrf/handsim/issue/91
locale-gen en_GB.utf8
export LC_ALL=en_GB.utf8
export LANG=en_GB.utf8
export LANGUAGE=en_GB
# Docker has problems with Qt X11 MIT-SHM extension
export QT_X11_NO_MITSHM=1
mkdir -p \$HOME
make test ARGS="-VV" || true
echo '# END SECTION'

echo '# BEGIN SECTION: cppcheck'
cd $WORKSPACE/handsim
sh tools/code_check.sh -xmldir $WORKSPACE/build/cppcheck_results || true
echo '# END SECTION'
DELIM

SOFTWARE_DIR="handsim"
DEPENDENCY_PKGS="${HANDSIM_DEPENDENCIES}"
. ${SCRIPT_DIR}/lib/docker_generate_dockerfile.bash
. ${SCRIPT_DIR}/lib/docker_run.bash
