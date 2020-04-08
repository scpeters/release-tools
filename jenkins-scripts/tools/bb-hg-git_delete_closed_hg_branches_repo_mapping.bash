#!/bin/bash

if ! which git_delete_closed_hg_branches.bash
then
  echo "git_delete_closed_hg_branches.bash not found in your PATH, please add it"
  exit
fi

REPO_MAPPING=$1
echo =========== Contents of ${REPO_MAPPING}
jq . ${REPO_MAPPING}
echo =========== Invoke script from each git-repo folder
for h in $(jq -r 'keys[]' ${REPO_MAPPING})
do
  echo   =========== delete closed branches from $(basename ${h})
  echo pushd $(jq -r ".[\"${h}\"]" ${REPO_MAPPING})
  pushd $(jq -r ".[\"${h}\"]" ${REPO_MAPPING})
  echo git_delete_closed_hg_branches.bash ${h}
  git_delete_closed_hg_branches.bash ${h}
  popd
done
