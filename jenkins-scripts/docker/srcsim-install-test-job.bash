#!/bin/bash -x

# Knowing Script dir beware of symlink
[[ -L ${0} ]] && SCRIPT_DIR=$(readlink ${0}) || SCRIPT_DIR=${0}
SCRIPT_DIR="${SCRIPT_DIR%/*}"

export GPU_SUPPORT_NEEDED=true

INSTALL_JOB_PREINSTALL_HOOK="""
# import the SRC repo
echo \"deb http://52.53.157.231/src ${DISTRO} main\" >\\
                                           /etc/apt/sources.list.d/src.list
apt-key adv --keyserver ha.pool.sks-keyservers.net --recv-keys D2486D2DD83DB69272AFE98867170598AF249743
wget -qO - http://52.53.157.231/src/src.key | sudo apt-key add -
apt-add-repository -y ppa:openjdk-r/ppa
sudo apt-get update
apt-get install -y openjdk-8-jdk
"""

INSTALL_JOB_POSTINSTALL_HOOK="""
echo '# BEGIN SECTION: testing by running qual1 launch file'
mkdir -p ~/.gazebo/models
wget -O /tmp/control.tar.gz http://models.gazebosim.org/control_console/model.tar.gz && tar xvf /tmp/control.tar.gz -C ~/.gazebo/models

export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd641

. /opt/ros/indigo/setup.bash
. /opt/nasa/indigo/setup.bash

cd /tmp
git clone https://github.com/ihmcrobotics/ihmc-open-robotics-software1
git checkout develop
./gradlew :Valkyrie:deployLocal1
cd /opt/ros/indigo/share/ihmc_ros_java_adapter
./gradlew --stop
./gradlew -x runJavaDelegate -PuseLocal=true

TEST_START=\`date +%s\`
timeout --preserve-status 400 roslaunch srcsim qual1.launch extra_gazebo_args:=\"-r\" init:=\"true\" || true
TEST_END=\`date +%s\`
DIFF=\`echo \"\$TEST_END - \$TEST_START\" | bc\`

if [ \$DIFF -lt 400 ]; then
   echo 'The test took less than 400s. Something bad happened'
   exit 1
fi
echo '# END SECTION'
"""
# Need bc to proper testing and parsing the time
export DEPENDENCY_PKGS DEPENDENCY_PKGS="wget bc python3-software-properties git"

. ${SCRIPT_DIR}/lib/generic-install-base.bash
