#!/bin/bash

cd $(dirname $(realpath $BASH_SOURCE))

NAM=simoncblyth
DOK=junosw/Dockerfile-junosw-cudaxx-runtimeplus-el9
DOKP=$(realpath ../$DOK)
VERSION=$(sed -n 's/^ARG CUDA_VERSION=//p' $DOKP)
TAG=cuda:$VERSION-runtimeplus-rockylinux9
SRC=https://github.com/simoncblyth/sandbox/blob/master/$DOK

vv="BASH_SOURCE PWD NAM DOK DOKP VERSION TAG SRC"

#defarg="info_build"
defarg="info"
arg=${1:-$defarg}

if [[ "$arg" =~ info ]]; then
   for v in $vv ; do printf "%30s : %s\n" "$v" "${!v}" ; done
fi 

if [[ "$arg" =~ build ]]; then
   docker build \
      --pull=false \
      --tag $NAM/$TAG --label "src=$SRC" --platform linux/amd64 - < $DOKP
   [ $? -ne 0 ] && echo $BASH_SOURCE - ERROR from build && exit 1 
fi


if [[ "$arg" =~ look ]]; then
    docker run --gpus all -it --rm $NAM/$TAG /bin/bash
   [ $? -ne 0 ] && echo $BASH_SOURCE - ERROR from look && exit 1 
fi



exit 0
