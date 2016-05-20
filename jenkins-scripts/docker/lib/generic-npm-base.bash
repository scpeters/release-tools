#!/bin/bash -x
set -e

if [[ -z ${SOFTWARE_DIR} ]]; then
    echo "SOFTWARE_DIR variable is unset. Please fix the code"
    exit 1
fi

ARTIFACTS_DIR=${ARTIFACTS_DIR:-$WORKSPACE/pkgs}

echo '# BEGIN SECTION: setup the testing enviroment'
# Define the name to be used in docker
DOCKER_JOB_NAME="npm_job"
. ${SCRIPT_DIR}/lib/boilerplate_prepare.sh
echo '# END SECTION'

cat > build.sh << DELIM
#!/bin/bash

###################################################
# Make project-specific changes here
#
set -ex
source ${TIMING_DIR}/_time_lib.sh ${WORKSPACE}

echo '# BEGIN SECTION: installing npm from repositories'
curl -sL https://deb.nodesource.com/setup_6.x | bash -
apt-get install -y nodejs
echo '# END SECTION'

if [ `expr length "${NPM_JOB_PRE_BUILDING_HOOK} "` -gt 1 ]; then
echo '# BEGIN SECTION: running pre NPM hook'
${NPM_JOB_PRENPM_HOOK}
echo '# END SECTION'
fi

echo '# BEGIN SECTION: build software'
cd ${WORKSPACE}/${SOFTWARE_DIR}
npm install
npm run build.dev
echo '# END SECTION'

echo '# BEGIN SECTION: generate the artifact'
BUILD_PROD_DIR=${WORKSPACE}/${SOFTWARE_DIR}/dist/prod
TIMESTAMP=\$(date '+%Y%m%d')
VERSION_SUFFIX="+hg\${TIMESTAMP}r${MERCURIAL_REVISION_SHORT}"

npm run build.prod
cp ${WORKSPACE}/${SOFTWARE_DIR}/Dockerfile \${BUILD_PROD_DIR}
mkdir -p ${ARTIFACTS_DIR}
zip ${ARTIFACTS_DIR}/ignbay${VERSION_SUFFIX}.zip -r \${BUILD_PROD_DIR}/*
echo '# END SECTION'

if [ `expr length "${NPM_JOB_POST_BUILDING_HOOK} "` -gt 1 ]; then
echo '# BEGIN SECTION: running post NPM hook'
${NPM_JOB_POSTNPM_HOOK}
echo '# END SECTION'
fi
DELIM

OSRF_REPOS_TO_USE=${OSRF_REPOS_TO_USE:=stable}
DEPENDENCY_PKGS="curl \
		 ca-certificates \
		 zip"

. ${SCRIPT_DIR}/lib/docker_generate_dockerfile.bash
. ${SCRIPT_DIR}/lib/docker_run.bash
