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

echo '# BEGIN SECTION: handsim installation'
apt-get install -y handsim
echo '# END SECTION'

echo '# BEGIN SECTION: test arat.world'
# In our nvidia machines, run the test to launch altas
# Seems like there is no failure in runs on precise pbuilder in
# our trusty machine. So we do not check for GRAPHIC_TESTS=true
mkdir -p \$HOME/.gazebo
# Workaround for bug:
# what():  locale::facet::_S_create_c_locale name not valid
export DEBIAN_FRONTEND=noninteractive
apt-get install locales
echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
locale-gen
timeout 180 gazebo worlds/arat.world || echo "Failure response in the launch command" && exit 1
echo "180 testing seconds finished successfully"
echo '# END SECTION'
DELIM

USE_OSRF_REPO=true
USE_GPU_DOCKER=true

. ${SCRIPT_DIR}/lib/docker_generate_dockerfile.bash
. ${SCRIPT_DIR}/lib/docker_run.bash
