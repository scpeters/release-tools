#!/bin/bash -x

#stop on error
set -e

cd ${WORKSPACE}/code
mkdir -p ${WORKSPACE}/code/build/cppcheck_results
sh tools/code_check.sh -xmldir $WORKSPACE/build/cppcheck_results || true
