#!/bin/bash -x

# Use always GPU in drcsim project
export GPU_SUPPORT_NEEDED=true

# Do not use the subprocess_reaper in debbuild. Seems not as needed as in
# testing jobs and seems to be slow at the end of jenkins jobs
export ENABLE_REAPER=false

. ${SCRIPT_DIR}/lib/boilerplate_prepare.sh

cat > build.sh << DELIM
###################################################
# Make project-specific changes here
#
set -ex

echo '# BEGIN SECTION: install graphic card support'
GRAPHIC_TESTS=false
if [ $GRAPHIC_CARD_NAME = Nvidia ] && [ $DISTRO = trusty ]; then
    GRAPHIC_TESTS=true

    if ${GRAPHIC_CARD_FOUND}; then
	apt-get install -y ${GRAPHIC_CARD_PKG}
	# Check to be sure version of kernel graphic card support is the same.
	# It will kill DRI otherwise
	CHROOT_GRAPHIC_CARD_PKG_VERSION=\$(dpkg -l | grep "^ii.*${GRAPHIC_CARD_PKG}\ " | awk '{ print \$3 }' | sed 's:-.*::')
	if [ "\${CHROOT_GRAPHIC_CARD_PKG_VERSION}" != "${GRAPHIC_CARD_PKG_VERSION}" ]; then
	   echo "Package ${GRAPHIC_CARD_PKG} has different version in chroot and host system. Maybe you need to update your host" 
	   exit 1
	fi
    fi
fi
echo '# END SECTION'

echo '# BEGIN SECTION: handsim installation'
apt-get install -y handsim
echo '# END SECTION'

echo '# BEGIN SECTION: test arat.world'
# In our nvidia machines, run the test to launch altas
# Seems like there is no failure in runs on precise pbuilder in
# our trusty machine. So we do not check for GRAPHIC_TESTS=true
mkdir -p \$HOME/.gazebo
timeout 180 gazebo worlds/arat.world || cat \$HOME/.gazebo/gzserver.log && echo "Failure response in the launch command"
echo "180 testing seconds finished successfully"
echo '# END SECTION'
DELIM

USE_OSRF_REPO=true
USE_GPU_DOCKER=true
SOFTWARE_DIR="handsim"

. ${SCRIPT_DIR}/lib/docker_generate_dockerfile.bash
. ${SCRIPT_DIR}/lib/docker_run.bash
