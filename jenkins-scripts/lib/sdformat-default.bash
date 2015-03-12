#!/bin/bash -x
set -e

# Define the name to be used in docker
DOCKER_JOB_NAME="sdformat_ci"
. ${SCRIPT_DIR}/lib/boilerplate_prepare.sh

cat > build.sh << DELIM
###################################################
# Make project-specific changes here
#
set -ex

# Step 2: configure and build
cd $WORKSPACE/build
cmake $WORKSPACE/sdformat
make -j${MAKE_JOBS}
make install
echo "HOME: $HOME"
echo "HOME2: \$HOME"
mkdir -p \$HOME
HOME=\$(pwd) LC_ALL=POSIX make test ARGS="-VV" || true

# Step 3: code check
cd $WORKSPACE/sdformat
sh tools/code_check.sh -xmldir $WORKSPACE/build/cppcheck_results || true
cat $WORKSPACE/build/cppcheck_results/*.xml
DELIM

cat > Dockerfile << DELIM_DOCKER
#######################################################
# Docker file to run build.sh

FROM jrivero/sdformat
MAINTAINER Jose Luis Rivero <jrivero@osrfoundation.org>

# If host is running squid-deb-proxy on port 8000, populate /etc/apt/apt.conf.d/30proxy
# By default, squid-deb-proxy 403s unknown sources, so apt shouldn't proxy ppa.launchpad.net
RUN route -n | awk '/^0.0.0.0/ {print \$2}' > /tmp/host_ip.txt
RUN echo "HEAD /" | nc \$(cat /tmp/host_ip.txt) 8000 | grep squid-deb-proxy \
  && (echo "Acquire::http::Proxy \"http://\$(cat /tmp/host_ip.txt):8000\";" > /etc/apt/apt.conf.d/30proxy) \
  && (echo "Acquire::http::Proxy::ppa.launchpad.net DIRECT;" >> /etc/apt/apt.conf.d/30proxy) \
  || echo "No squid-deb-proxy detected on docker host"

# Map the workspace into the container
RUN mkdir -p ${WORKSPACE}
RUN \
  echo "deb http://archive.ubuntu.com/ubuntu ${DISTRO} main restricted universe multiverse" >> /etc/apt/sources.list && \\
  echo "deb http://archive.ubuntu.com/ubuntu ${DISTRO}-updates main restricted universe multiverse" >> /etc/apt/sources.list && \\
  echo "deb http://archive.ubuntu.com/ubuntu ${DISTRO}-security main restricted universe multiverse" >> /etc/apt/sources.list 
RUN echo "${TODAY_STR}"
RUN apt-get update
RUN apt-get install -y ${BASE_DEPENDENCIES} ${SDFORMAT_BASE_DEPENDENCIES}
ADD sdformat ${WORKSPACE}/sdformat
ADD build.sh build.sh
RUN chmod +x build.sh
DELIM_DOCKER

sudo rm -fr ${WORKSPACE}/build
mkdir -p ${WORKSPACE}/build

sudo docker pull jrivero/sdformat
sudo docker build -t ${DOCKER_TAG} .
sudo docker run \
            --cidfile=${CIDFILE} \
            -v ${WORKSPACE}/build:${WORKSPACE}/build \
            -t ${DOCKER_TAG} \
            /bin/bash build.sh

CID=$(cat ${CIDFILE})

sudo docker stop ${CID}
sudo docker rm ${CID}
