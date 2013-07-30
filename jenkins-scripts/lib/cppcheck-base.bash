#!/bin/bash -x

#stop on error
set -e

# Mercurial jenkins plugin can not handle variables for checking
# source. Manual code to do that

if [ -z ${SOFTWARE} ]; then
    echo "Need SOFTWARE variable to be defined"
    exit 1
fi

SOFTWARE_DIR=${WORKSPACE}/${SOFTWARE}

if [ ! -d ${SOFTWARE_DIR} ]; then
    hg clone https://bitbucket.org/osrf/$SOFTWARE ${SOFTWARE_DIR}
else
    cd ${SOFTWARE_DIR}
    hg revert --all 
    hg update --clean
fi
    
cd ${SOFTWARE_DIR}
hg update ${MERCURIAL_REVISION}

# Run cpp check
rm -fr ${WORKSPACE}/cppcheck_results
mkdir -p ${WORKSPACE}/cppcheck_results
sh tools/code_check.sh -xmldir $WORKSPACE/cppcheck_results || true
