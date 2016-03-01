#!/bin/bash -xe

STATUS=${1}

if [[ $? -lt 1 ]]; then
    echo "Usage: $0 [inprogress|ok|failed]"
    exit 1
fi

if [[ -f $BITBUCKET_BUILD_STATUS_FILE ]]; then
    echo "BITBUCKET_BUILD_STATUS_FILE does not correspond to a file"
    echo "content: ${BITBUCKET_BUILD_STATUS_FILE}"
    exit 1
fi

if [[ ! -f ${BITBUCKET_USER_PASS_FILE} ]]; then
  echo "Bitbucket user pass not found in file \${BITBUCKET_USER_PASS_FILE}"
  exit 1
fi

echo "BEGIN SECTION: build status in bitbucket: ${STATUS} (hidden)"
set +x # keep password secret
BITBUCKET_USER_PASS=`cat $BITBUCKET_USER_PASS_FILE`
${WORKSPACE}/scripts/jenkins-scripts/python-bitbucket/set_status_from_file.py \
    --user osrf_jenkins  \
    --pass ${BITBUCKET_USER_PASS} \
    --status ${STATUS} \
    --load_from_file ${CONFIG_FILE_PATH} >& pybitbucket.log
set -x # back to debug
echo '# END SECTION'
