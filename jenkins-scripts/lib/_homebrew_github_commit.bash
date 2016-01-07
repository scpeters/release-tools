# parameters:
# - TAP_PREFIX
# - PACKAGE_ALIAS
# - VERSION
#
# exports:
# - GITHUB_FORK_BRANCH

if [ -z ${PACKAGE_ALIAS} ]; then
    echo "PACKAGE_ALIAS variable is empty"
    exit -1
fi

if [ -z ${TAP_PREFIX} ]; then
    echo "TAP_PREFIX variable is empty"
    exit -1
fi

if [ -z ${VERSION} ]; then
    echo "VERSION variable is empty"
    exit -1
fi

GIT="git -C ${TAP_PREFIX}"

# create branch with name and sanitized version string
export GITHUB_FORK_BRANCH="${PACKAGE_ALIAS}_`echo ${VERSION} | tr ' ~:^?*[' '_'`"

DIFF_LENGTH=`${GIT} diff | wc -l`
if [ ${DIFF_LENGTH} -eq 0 ]; then
  echo No formula modifications found, aborting
  exit -1
fi
echo ==========================================================
${GIT} diff
echo ==========================================================
echo '# END SECTION'

echo
echo "# BEGIN SECTION: commit to branch (${GITHUB_FORK_BRANCH})"
${GIT} remote add fork git@github.com:osrfbuild/homebrew-simulation.git
# unshallow to get a full clone able to push
${GIT} fetch --unshallow
${GIT} config user.name "OSRF Build Bot"
${GIT} config user.email "osrfbuild@osrfoundation.org"
${GIT} remote -v
${GIT} checkout -b ${GITHUB_FORK_BRANCH}
${GIT} commit ${FORMULA_PATH} -m "${PACKAGE_ALIAS} ${VERSION}"
echo
${GIT} status
echo
${GIT} show HEAD
echo
${GIT} push -u fork ${GITHUB_FORK_BRANCH}
echo '# END SECTION'
