#!/bin/bash -x

# Not really GPU but need a valid display
export GPU_SUPPORT_NEEDED=true

echo '# BEGIN SECTION: setup the testing enviroment'
DOCKER_JOB_NAME="gazebo_ci"
. ${SCRIPT_DIR}/lib/boilerplate_prepare.sh
echo '# END SECTION'

cat > build.sh << DELIM
###################################################
# Make project-specific changes here
#
set -ex

echo '# BEGIN SECTION: download models'
mkdir -p \$HOME/.gazebo/models
wget -P /tmp/ https://bitbucket.org/osrf/gazebo_models/get/default.tar.gz
tar -xvf /tmp/default.tar.gz -C \$HOME/.gazebo/models --strip 1
rm /tmp/default.tar.gz
echo '# END SECTION'

echo '# BEGIN SECTION: npm install'
cd $WORKSPACE/gazebojs
npm install
echo '# END SECTION'

echo '# BEGIN SECTION: node-gyp configure and build'
node-gyp configure
node-gyp build
echo '# END SECTION'

echo '# BEGIN SECTION: running tests'
cd $WORKSPACE/gazebojs
npm test
echo '# END SECTION'

DELIM

SOFTWARE_DIR="gazebojs"
OSRF_REPOS_TO_USE="stable"

DEPENDENCY_PKGS="${BASE_DEPENDENCIES} wget gazebo7 libgazebo7-dev libjansson-dev mercurial nodejs nodejs-legacy npm"

. ${SCRIPT_DIR}/lib/docker_generate_dockerfile.bash
. ${SCRIPT_DIR}/lib/docker_run.bash
