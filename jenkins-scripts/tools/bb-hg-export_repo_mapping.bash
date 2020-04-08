#!/bin/bash

which hg-fast-export.sh || \
  echo "hg-fast-export.sh not found in your PATH, please add it" && exit

REPO_MAPPING=$1
echo =========== Contents of ${REPO_MAPPING}
jq . ${REPO_MAPPING}
echo =========== Create git-repo folders
echo creating the following git-repo folders:
echo mkdir -p $(jq '.[]' ${REPO_MAPPING})
mkdir -p $(jq '.[]' ${REPO_MAPPING})
echo =========== Invoke script from each git-repo folder
for h in $(jq -r 'keys[]' ${REPO_MAPPING})
do
  echo pushd $(jq ".[\"${h}\"]" ${REPO_MAPPING})
  pushd $(jq ".[\"${h}\"]" ${REPO_MAPPING})
  echo hg-fast-export.sh -r ${h}
  hg-fast-export.sh -r ${h}
  echo popd
  popd
done
