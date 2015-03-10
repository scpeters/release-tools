#!/bin/bash -x

# RELEASE_REPO_DIRECTORY control the migration from single distribution
# to multidistribution. If not set, go for ubuntu in single distribution
# mode
if [ -z $RELEASE_REPO_DIRECTORY ]; then
    RELEASE_REPO_DIRECTORY=ubuntu
fi;

NIGHTLY_MODE=false
if [ "${VERSION}" = "nightly" ]; then
   NIGHTLY_MODE=true
fi

# Do not use the subprocess_reaper in debbuild. Seems not as needed as in
# testing jobs and seems to be slow at the end of jenkins jobs
export ENABLE_REAPER=false

. ${SCRIPT_DIR}/lib/boilerplate_prepare.sh

cat > build.sh << DELIM
###################################################
# Make project-specific changes here
#
#!/usr/bin/env bash
set -ex

mkdir -p $WORKSPACE/pkgs
touch $WORKSPACE/pkgs/foo.deb
touch $WORKSPACE/pkgs/libfoo.deb

PKGS=\`find $WORKSPACE/pkgs *.deb || true\`

FOUND_PKG=0
for pkg in \${PKGS}; do
    echo "found \$pkg"
    # && exit 1
    cp \${pkg} $WORKSPACE/pkgs
    FOUND_PKG=1
done
# check at least one upload
test \$FOUND_PKG -eq 1 || exit 1
DELIM

cat > Dockerfile << DELIM_DOCKER
#######################################################
# Docker file to run build.sh

FROM osrf/ubuntu_armhf:${DISTRO}
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
ADD build.sh build.sh
RUN chmod +x build.sh
RUN ./build.sh
DELIM_DOCKER

#
# Make project-specific changes here
###################################################

if [[ $ARCH == armhf ]]; then
  sudo docker pull osrf/ubuntu_armhf
  sudo docker build -t $PACKAGE/debbuild .
else
  echo "Architecture still unsupported"
  exit 1
fi

CID"=${WORKSPACE}/$PACKAGE.cid"

sudo docker run -t $PACKAGE/debbuild --cidfile= .

sudo docker cp ${CID}:${WORKSPACE}/pkgs ${WORKSPACE}/pkgs
sudo docker stop ${CID}
