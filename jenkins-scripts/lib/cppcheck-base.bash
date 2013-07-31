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
  sudo apt-get install -y cppcheck bzip2
fi

rm -fr ${WORKSPACE}/source_code/
mkdir -p ${WORKSPACE}/source_code/

tar jxf *.tar.bz2 -C ${WORKSPACE}/source_code/
mkdir -p ${WORKSPACE}/source_code/$SOFTWARE/build
cd ${WORKSPACE}/source_code/$SOFTWARE/build

# Run cpp check
sh tools/code_check.sh -xmldir ${WORKSPACE}/${SOFTWARE}/build/cppcheck_results || true
