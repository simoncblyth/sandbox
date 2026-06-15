#!/bin/bash

usage(){ cat << EOU
build.sh
==========

::

    ~/sandbox/local/build.sh info



* https://hub.docker.com/r/junosw/base/tags


hub.docker.com handles::

    junosw/base:el9
    junosw/base:el9-9.4

    simoncblyth/junosw:el9.4-cuda13.1.2-opticks


EOU
}

cd $(dirname $(realpath $BASH_SOURCE))


#BASIS="cuda"     ## based off nvidia/cuda
BASIS="junosw"  ## based off junosw/base:el9-9.4

case $BASIS in
  cuda)   DOK=junosw/Dockerfile-junosw-cudaxx-runtimeplus-el9 ;;
  junosw) DOK=junosw/Dockerfile-from-junosw-cudaxx-runtimeplus-el9 ;;
esac

SRC=https://github.com/simoncblyth/sandbox/blob/master/$DOK
DOKP=$(realpath ../$DOK)
CUDA_VERSION=$(sed -n 's/^ARG CUDA_VERSION=//p' $DOKP)  ## eg 13.1.2
CUDA_VERS=$(echo "${CUDA_VERSION}" | cut -d. -f1-2 )    ## eg 13.1


case $BASIS in
  cuda)   TAG=cuda:$CUDA_VERS-runtimeplus-rockylinux9   ;;
  junosw) TAG=junosw:el9.4-cuda$CUDA_VERS-opticks    ;;
esac


NAM=simoncblyth

vv="BASH_SOURCE PWD NAM DOK DOKP CUDA_VERSION CUDA_VERS TAG SRC"

#defarg="info_build"
defarg="info"
arg=${1:-$defarg}

if [[ "$arg" =~ info ]]; then
   for v in $vv ; do printf "%30s : %s\n" "$v" "${!v}" ; done
   printf "%30s : %s\n" "NAM/TAG" "$NAM/$TAG"
fi

if [[ "$arg" =~ build ]]; then
   docker build \
      --pull=false \
      --label "org.opencontainers.image.revision=$(git rev-parse HEAD)" \
      --label "org.opencontainers.image.created=$(date -u +'%Y-%m-%dT%H:%M:%SZ')" \
      --label "org.opencontainers.image.source=$SRC" \
      --tag $NAM/$TAG \
      --platform linux/amd64 - < $DOKP
   [ $? -ne 0 ] && echo $BASH_SOURCE - ERROR from build && exit 1
fi


if [[ "$arg" =! inspect ]]; then
   docker inspect --format='{{json .Config.Labels}}' $NAM/$TAG | jq   # jq pretty prints json
   [ $? -ne 0 ] && echo $BASH_SOURCE - ERROR from inspect && exit 1
fi


if [[ "$arg" =~ look ]]; then
    docker run --gpus all -it --rm $NAM/$TAG /bin/bash
   [ $? -ne 0 ] && echo $BASH_SOURCE - ERROR from look && exit 1
fi



exit 0
