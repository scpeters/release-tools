#!/bin/bash -x

echo '# BEGIN SECTION: setup the testing enviroment'
# Define the name to be used in docker
DOCKER_JOB_NAME="xenial-cmake"
. ${SCRIPT_DIR}/lib/boilerplate_prepare.sh

cat > build.sh << DELIM
###################################################
# Make project-specific changes here
#
set -ex

mkdir -p $WORKSPACE/test/build
cd $WORKSPACE/test

cat > CMakeLists.txt << FOO
cmake_minimum_required(VERSION 3.2)
include(FindPkgConfig)
pkg_check_modules(GLIB2 glib-2.0)
FOO

cd $WORKSPACE/test/build
cmake ..
grep ^GLIB2 CMakeCache.txt
DELIM

USE_OSRF_REPO=true
SOFTWARE_DIR=""
DEPENDENCY_PKGS="${BASE_DEPENDENCIES} glib2.0-dev cmake"

. ${SCRIPT_DIR}/lib/docker_generate_dockerfile.bash
. ${SCRIPT_DIR}/lib/docker_run.bash
