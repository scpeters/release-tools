# 
# Script to generate the dockerfile needed for running the build.sh script
#
# Inputs used:
#   - DISTRO          : base distribution (ex: vivid)
#   - ARCH            : [default amd64] base arquitecture (ex: amd64)
#   - USE_OSRF_REPO   : [default false] true|false if add the packages.osrfoundation.org to the sources.list
#   - USE_ROS_REPO    : [default false] true|false if add the packages.ros.org to the sources.list
#   - DEPENDENCY_PKGS : (optional) packages to be installed in the image
#   - SOFTWARE_DIR    : (optional) directory to copy inside the image

if [[ -z ${ARCH} ]]; then
  echo "Arch undefined, default to amd64"
  export ARCH="amd64"
fi

# Select the docker container depenending on the ARCH
case ${ARCH} in
  'amd64') 
     FROM_VALUE=ubuntu:${DISTRO}
     ;;
  'i386')
      # There are no i386 official images. Only 14.04 (trusty) is available
     # https://registry.hub.docker.com/u/32bit/ubuntu/tags/manage/
     if [[ $DISTRO != 'trusty' ]]; then
	 echo "Only trusty images are avilable for i386"
	 exit 1
     fi

     FROM_VALUE=32bit/ubuntu:14.04
     ;;
 'armhf')
     FROM_VALUE=osrf/ubuntu_armhf:${DISTRO}
     ;;
  *)
     echo "Arch unknown"
     exit 1
esac

[[ -z ${USE_OSRF_REPO} ]] && USE_OSRF_REPO=false
[[ -z ${USE_ROS_REPO} ]] && USE_ROS_REPO=false

echo '# BEGIN SECTION: create the Dockerfile'
cat > Dockerfile << DELIM_DOCKER
#######################################################
# Docker file to run build.sh

FROM ${FROM_VALUE}
MAINTAINER Jose Luis Rivero <jrivero@osrfoundation.org>

# If host is running squid-deb-proxy on port 8000, populate /etc/apt/apt.conf.d/30proxy
# By default, squid-deb-proxy 403s unknown sources, so apt shouldn't proxy ppa.launchpad.net
RUN route -n | awk '/^0.0.0.0/ {print \$2}' > /tmp/host_ip.txt
RUN echo "HEAD /" | nc \$(cat /tmp/host_ip.txt) 8000 | grep squid-deb-proxy \
  && (echo "Acquire::http::Proxy \"http://\$(cat /tmp/host_ip.txt):8000\";" > /etc/apt/apt.conf.d/30proxy) \
  && (echo "Acquire::http::Proxy::ppa.launchpad.net DIRECT;" >> /etc/apt/apt.conf.d/30proxy) \
  || echo "No squid-deb-proxy detected on docker host"
DELIM_DOCKER

if [[ ${ARCH} != 'armhf' ]]; then
cat >> Dockerfile << DELIM_DOCKER_ARCH
# Note that main,restricted and universe are not here, only multiverse
# main, restricted and unvierse are already setup in the original image
RUN echo "deb http://archive.ubuntu.com/ubuntu ${DISTRO} multiverse" \\
                                                       >> /etc/apt/sources.list && \\
    echo "deb http://archive.ubuntu.com/ubuntu ${DISTRO}-updates multiverse" \\
                                                       >> /etc/apt/sources.list && \\
    echo "deb http://archive.ubuntu.com/ubuntu ${DISTRO}-security main restricted universe multiverse" && \\
                                                       >> /etc/apt/sources.list
DELIM_DOCKER_ARCH
fi

if ${USE_OSRF_REPO} || ${USE_ROS_REPO}; then
cat >> Dockerfile << DELIM_WGET
# Not really needed to run the apt-get to install wget?
# RUN apt-get update && apt-get install -y wget
RUN apt-get install -y wget
DELIM_WGET
fi

if ${USE_OSRF_REPO}; then
cat >> Dockerfile << DELIM_OSRF_REPO
RUN echo "deb http://packages.osrfoundation.org/gazebo/ubuntu ${DISTRO} main" > \\
                                                /etc/apt/sources.list.d/osrf.list && \\
    wget http://packages.osrfoundation.org/gazebo.key -O - | apt-key add - 
DELIM_OSRF_REPO
fi

if ${USE_ROS_REPO}; then
cat >> Dockerfile << DELIM_ROS_REPO
RUN echo "deb http://packages.ros.org/ros/ubuntu ${DISTRO} main" > \\
                                                /etc/apt/sources.list.d/ros.list && \\
   curl -LsS https://raw.githubusercontent.com/ros/rosdistro/master/ros.key - | sudo apt-key add -
DELIM_ROS_REPO
fi

# Dart repositories
if ${DART_FROM_PKGS} || ${DART_COMPILE_FROM_SOURCE}; then
cat >> Dockerfile << DELIM_DOCKER_DART_PKGS
# Install dart from pkgs 
RUN apt-get install -y python-software-properties apt-utils software-properties-common
RUN apt-add-repository -y ppa:libccd-debs
RUN apt-add-repository -y ppa:fcl-debs
RUN apt-add-repository -y ppa:dartsim
DELIM_DOCKER_DART_PKGS
fi

# Handle special INVALIDATE_DOCKER_CACHE keyword by set a random
# string in the moth year str
if [[ -n ${INVALIDATE_DOCKER_CACHE} ]]; then
cat >> Dockerfile << DELIM_DOCKER_INVALIDATE
RUN echo 'BEGIN SECTION: invalidate full docker cache'
RUN echo "Detecting content in INVALIDATE_DOCKER_CACHE. Invalidating it"
RUN echo "Invalidate cache enabled. ${DOCKER_RND_ID}"
RUN echo 'END SECTION'
DELIM_DOCKER_INVALIDATE
fi

# Packages that will be installed and cached by docker. In a non-cache
# run below, the docker script will check for the latest updates
PACKAGES_CACHE_AND_CHECK_UPDATES="${BASE_DEPENDENCIES} ${DEPENDENCY_PKGS}"

if $USE_GPU_DOCKER; then
  PACKAGES_CACHE_AND_CHECK_UPDATES="${PACKAGES_CACHE_AND_CHECK_UPDATES} ${GRAPHIC_CARD_PKG}"
fi

cat >> Dockerfile << DELIM_DOCKER3
# Invalidate cache monthly
# This is the firt big installation of packages on top of the raw image. 
# The expection of updates is low and anyway it is cathed by the next
# update command below
RUN echo "${MONTH_YEAR_STR}"
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update && \
    apt-get install -y ${PACKAGES_CACHE_AND_CHECK_UPDATES}

# This is killing the cache so we getg the most recent packages if there
# was any update
RUN echo "Invalidating cache $(( ( RANDOM % 100000 )  + 1 ))"
RUN apt-get update && \
    apt-get install -y ${PACKAGES_CACHE_AND_CHECK_UPDATES}
ENV DISPLAY ${DISPLAY}

# Check to be sure version of kernel graphic card support is the same.
# It will kill DRI otherwise
RUN CHROOT_GRAPHIC_CARD_PKG_VERSION=\$(dpkg -l | grep "^ii.*${GRAPHIC_CARD_PKG}\ " | awk '{ print \$3 }' | sed 's:-.*::') \\
    if [ "\${CHROOT_GRAPHIC_CARD_PKG_VERSION}" != "${GRAPHIC_CARD_PKG_VERSION}" ]; then \\
       echo "Package ${GRAPHIC_CARD_PKG} has different version in chroot and host system" \\
       echo "Maybe you need to update your host" \\
       exit 1 \\
   fi
# Map the workspace into the container
RUN mkdir -p ${WORKSPACE}
DELIM_DOCKER3

if [[ -n ${SOFTWARE_DIR} ]]; then
cat >> Dockerfile << DELIM_DOCKER4
COPY ${SOFTWARE_DIR} ${WORKSPACE}/${SOFTWARE_DIR}
DELIM_DOCKER4
fi

cat >> Dockerfile << DELIM_DOCKER4
COPY build.sh build.sh
RUN chmod +x build.sh
DELIM_DOCKER4
echo '# END SECTION'

echo '# BEGIN SECTION: see Dockerfile'
cat Dockerfile
echo '# END SECTION'
