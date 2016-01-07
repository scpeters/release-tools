# parameters:
# - GITHUB_FORK_BRANCH

if [ -z ${GITHUB_FORK_BRANCH} ]; then
    echo "GITHUB_FORK_BRANCH variables is empty"
    exit -1
fi

echo '# BEGIN SECTION: pull request creation'
# Check for hub command
HUB=hub
if ! which ${HUB} ; then
  if [ ! -s hub-linux-amd64-2.2.2.tgz ]; then
    echo
    echo Downloading hub...
    wget -q https://github.com/github/hub/releases/download/v2.2.2/hub-linux-amd64-2.2.2.tgz
    echo Downloaded
  fi
  HUB=`tar tf hub-linux-amd64-2.2.2.tgz | grep /hub$`
  tar xf hub-linux-amd64-2.2.2.tgz ${HUB}
  HUB=${PWD}/${HUB}
fi

# This cd needed because -C doesn't seem to work for pull-request
# https://github.com/github/hub/issues/1020
cd ${TAP_PREFIX}
PR_URL=$(${HUB} -C ${TAP_PREFIX} pull-request \
  -b osrf:master \
  -h osrfbuild:${GITHUB_FORK_BRANCH} \
  -m "${PACKAGE_ALIAS} ${VERSION}")

echo "Pull request created: ${PR_URL}"
echo '# END SECTION'
