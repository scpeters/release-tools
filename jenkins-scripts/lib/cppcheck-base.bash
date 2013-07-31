#!/bin/bash -x

#stop on error
set -e

# Mercurial jenkins plugin can not handle variables for checking
# source. Manual code to do that

if [ -z ${SOFTWARE} ]; then
    echo "Need SOFTWARE variable to be defined"
    exit 1
fi

QUERY_HOST_PACKAGES=$(dpkg-query -Wf'${db:Status-abbrev}' cppcheck 2>&1) || true
if [[ -n ${QUERY_HOST_PACKAGES} ]]; then
  sudo apt-get install -y cppcheck
fi

SOFTWARE_DIR=${WORKSPACE}/${SOFTWARE}

if [ ! -d ${SOFTWARE_DIR} ]; then
    hg clone https://bitbucket.org/osrf/$SOFTWARE ${SOFTWARE_DIR}
else
    cd ${SOFTWARE_DIR}
    hg revert --all 
    hg update --clean
    hg pull
fi
    
cd ${SOFTWARE_DIR}
hg update ${MERCURIAL_REVISION}

# Run cpp check
rm -fr ${SOFTWARE_DIR}/cppcheck_results
mkdir -p ${SOFTWARE_DIR}/cppcheck_results
sh tools/code_check.sh -xmldir ${SOFTWARE_DIR}/cppcheck_results || true
