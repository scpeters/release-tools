#!/bin/bash

if ! which hg-fast-export.sh
then
  echo "hg-fast-export.sh not found in your PATH, please add it"
  exit
fi

REPO_MAPPING=$1
echo =========== Contents of ${REPO_MAPPING}
jq . ${REPO_MAPPING}
echo =========== Create git-repo folders
echo creating the following git-repo folders:
echo mkdir -p $(jq -r '.[]' ${REPO_MAPPING})
mkdir -p $(jq -r '.[]' ${REPO_MAPPING})
echo =========== Invoke script from each git-repo folder
for h in $(jq -r 'keys[]' ${REPO_MAPPING})
do
  echo   =========== convert $(basename ${h})
  pushd $(jq -r ".[\"${h}\"]" ${REPO_MAPPING})
  git init
  echo hg-fast-export.sh -r ${h}
  trap "echo hg-fast-export.sh failed to export ${h}, running again with --force; hg-fast-export.sh -r ${h} --force" ERR
  hg-fast-export.sh -r ${h}
  popd
done
