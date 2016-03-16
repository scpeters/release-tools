#!/bin/bash -xe

# Knowing Script dir beware of symlink
[[ -L ${0} ]] && SCRIPT_DIR=$(readlink ${0}) || SCRIPT_DIR=${0}
SCRIPT_DIR="${SCRIPT_DIR%/*}"

STATUS=${1}

# Source bitbucket configs
. ${SCRIPT_DIR}/_bitbucket_configs.bash

if [[ "$#" -ne 1 ]]; then
    echo "Usage: $0 [inprogress|ok|failed]"
    exit 1
fi

if [[ ! -f $BITBUCKET_BUILD_STATUS_FILE ]]; then
    echo "BITBUCKET_BUILD_STATUS_FILE does not correspond to a file"
    echo "content: ${BITBUCKET_BUILD_STATUS_FILE}"
    exit 1
fi

if [[ ! -f ${BITBUCKET_USER_PASS_FILE} ]]; then
  echo "Bitbucket user pass not found in file: ${BITBUCKET_USER_PASS_FILE}"
  exit 1
fi

echo "BEGIN SECTION: build status in bitbucket: ${STATUS} (hidden)"
set +x # keep password secret
BITBUCKET_USER_PASS=$(cat ${BITBUCKET_USER_PASS_FILE})
BITBUCKET_API_RESULT=true
${WORKSPACE}/scripts/jenkins-scripts/python-bitbucket/set_status_from_file.py \
    --user osrf_jenkins  \
    --pass ${BITBUCKET_USER_PASS} \
    --status ${STATUS} \
    --load_from_file ${BITBUCKET_BUILD_STATUS_FILE} >& ${BITBUCKET_LOG_FILE} || BITBUCKET_API_RESULT=false
set -x # back to debug
echo '# END SECTION'

if ! $BITBUCKET_API_RESULT; then
  echo 'BEGIN SECTION: build status FAILED'
  echo 'The call from the python client to bitbucket to set the build status failed'
  echo "Please check out the workspace for the file: ${BITBUCKET_LOG_FILE}"
  echo '# END SECTION'
fi