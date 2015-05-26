# TODO: run inside docker as a normal user and replace the sudo calls
# This are usually for debbuilders
sudo rm -fr ${WORKSPACE}/pkgs
sudo mkdir -p ${WORKSPACE}/pkgs
# This are usually for continous integration jobs
sudo rm -fr ${WORKSPACE}/build
sudo mkdir -p ${WORKSPACE}/build

sudo docker build -t ${DOCKER_TAG} .

if $USE_GPU_DOCKER; then
  GPU_PARAMS_STR="--privileged \
                     -e \"DISPLAY=unix$DISPLAY\" \
		     -v=\"/sys:/sys:r\" \
                     -v=\"/tmp/.X11-unix:/tmp/.X11-unix:rw\""
fi

sudo docker run $GPU_PARAMS_STR  \
            --cidfile=${CIDFILE} \
            -v ${WORKSPACE}/pkgs:${WORKSPACE}/pkgs \
            -v ${WORKSPACE}/build:${WORKSPACE}/build \
            -t ${DOCKER_TAG} \
            /bin/bash build.sh

CID=$(cat ${CIDFILE})

# Not all versions of docker handle return values in a right way
# https://github.com/docker/docker/issues/354 
ret=$(sudo docker inspect --format='{{.State.ExitCode}}' ${CID})
echo "Returned value from run command: ${ret}"

sudo docker stop ${CID} || true
sudo docker rm ${CID} || true

if [[ -z ${KEEP_WORKSPACE} ]]; then
    # Clean previous results, need to next command not to fail
    sudo rm -fr "${WORKSPACE}/*_results*"
    # Export results, if any
    for d in $(find ${WORKSPACE}/build -name '*_results' -type d); do
	sudo mv ${d} ${WORKSPACE}/
    done
    # Clean the whole build directory
    sudo rm -fr ${WORKSPACE}/build
fi

if [[ $ret != 0 ]]; then
    echo "Docker container returned a non zero value"
    exit $ret
fi
