#!/bin/bash -x

# Knowing Script dir beware of symlink
[[ -L ${0} ]] && SCRIPT_DIR=$(readlink ${0}) || SCRIPT_DIR=${0}
SCRIPT_DIR="${SCRIPT_DIR%/*}"

export ENABLE_ROS=false
export DOCKER_JOB_NAME="ihmc_controller_job"
. ${SCRIPT_DIR}/lib/boilerplate_prepare.sh

cat > build.sh << DELIM
###################################################
# Make project-specific changes here
#
#!/usr/bin/env bash
set -ex

mkdir -p ${WORKSPACE}/pkgs

echo 'BEGIN SECTION: install PPA for Java 8'
apt-add-repository -y ppa:webupd8team/java
apt-get update
echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | /usr/bin/debconf-set-selections
export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
echo 'END SECTION'

echo 'BEGIN SECTION: run gradle'
cd ${WORKSPACE}/repo

git checkout develop
./gradlew :Valkyrie:deployLocal
echo 'END SECTION'

tar cvfz ${WORKSPACE}/pkgs/valkyrie_controller.tar.gz valkyrie

echo 'END SECTION'
DELIM

DEPENDENCY_PKGS="gradle \
                 software-properties-common git \
                 devscripts \
		 ubuntu-dev-tools \
		 debhelper \
		 wget \
		 ca-certificates \
		 equivs \
		 dh-make \
		 mercurial \
		 git"

. ${SCRIPT_DIR}/lib/docker_generate_dockerfile.bash
. ${SCRIPT_DIR}/lib/docker_run.bash
