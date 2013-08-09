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

CODE_DESTDIR=${WORKSPACE}/${SOFTWARE}

rm -fr ${CODE_DESTDIR}
mkdir -p ${CODE_DESTDIR}

tar -xjf ${WORKSPACE}/source.tar.bz2 -C ${WORKSPACE}

# Trick to simulate current script

# Run cpp check
cd ${CODE_DESTDIR}
chmod +x tools/code_check.sh
mv ${CODE_DESTDIR}/build ${WORKSPACE}
ls ../build/*
sh tools/code_check.sh -xmldir ${WORKSPACE}/build/cppcheck_results || true
