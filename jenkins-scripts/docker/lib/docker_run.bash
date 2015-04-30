# TODO: run inside docker as a normal user and replace the sudo calls
# This are usually for debbuilders
sudo rm -fr ${WORKSPACE}/pkgs
sudo mkdir -p ${WORKSPACE}/pkgs
# This are usually for continous integration jobs
sudo rm -fr ${WORKSPACE}/build
sudo mkdir -p ${WORKSPACE}/build

sudo docker build -t ${DOCKER_TAG} .

[[ -z $USE_GPU_DOCKER ]] && export USE_GPU_DOCKER=""

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

sudo docker stop ${CID} || true
sudo docker rm ${CID} || true
