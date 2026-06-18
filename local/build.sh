#!/bin/bash

sandbox_usage(){ cat << EOU
build.sh
==========

::

    ~/sandbox/local/build.sh usage      ## emit this help message
    ~/sandbox/local/build.sh info       ## dump variable values
    ~/sandbox/local/build.sh build      ## build the docker image - remember to increment IMG_VERS if are going to push the image to docker hub
    ~/sandbox/local/build.sh login      ## only needed very infrequently as writes to auths sectionm of ~/.docker/config.json
    ~/sandbox/local/build.sh push       ## upload new layers using a double tagging technique
    ~/sandbox/local/build.sh inspect    ## dump metadata in the image
    ~/sandbox/local/build.sh look       ## run the image
    ~/sandbox/local/build.sh save       ## save the image to tar.gz file
    ~/sandbox/local/build.sh ls         ## list the tarball
    ~/sandbox/local/build.sh scp        ## scp the tarball

Relevant base docker handles from https://hub.docker.com/r/junosw/base/tags::

    junosw/base:el9
    junosw/base:el9-9.4

docker handles this script creates, from https://hub.docker.com/r/simoncblyth/junosw/tags::

    simoncblyth/junosw:v1.0.0
    simoncblyth/junosw:el9.4-cuda13.1-opticks


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
IMG_VERS=v1.0.2
NAM=simoncblyth
TOP=junosw
PUSH_REF=$NAM/$TOP:$IMG_VERS
FOLD=/tmp/$USER/sandbox
mkdir -p $FOLD

case $BASIS in
  cuda)   TAG=cuda:$CUDA_VERS-runtimeplus-rockylinux9   ;;
  junosw) TAG=$TOP:el9.4-cuda$CUDA_VERS-opticks    ;;
esac

TGZPATH=$FOLD/${TAG//:/-}_${IMG_VERS}.tar.gz


vv="BASH_SOURCE PWD NAM DOK DOKP CUDA_VERSION CUDA_VERS TAG SRC IMG_VERS TOP PUSH_REF FOLD TGZPATH"

#defarg="info_build"
defarg="info"
arg=${1:-$defarg}

if [[ "$arg" =~ usage|help ]]; then
    sandbox_usage
fi

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


if [[ "$arg" =~ login ]]; then
   [ -z "$DOCKER_PAT_SIMONCBLYTH" ] && echo $BASH_SOURCE - ERROR - NEED DOCKER_PAT_SIMONCBLYTH FOR LOGIN && exit 1
   echo "$DOCKER_PAT_SIMONCBLYTH" | docker login -u simoncblyth --password-stdin

   # The above docker login updates the auths section of  ~/.docker/config.json
   # this persists the logged in status
   #
   #   echo -n simoncblyth:$DOCKER_PAT_SIMONCBLYTH | openssl base64 -A
fi


if [[ "$arg" =~ push ]]; then

    echo "$BASH_SOURCE : Registering blueprint tag on Docker Hub..."
    docker push $NAM/$TAG
    [ $? -ne 0 ] && echo $BASH_SOURCE ERROR from pushing blueprint tag && exit 1

    echo "$BASH_SOURCE : Creating and pushing immutable release version tag ($IMG_VERS)..."
    docker tag $NAM/$TAG $PUSH_REF
    ## ABOVE JUST CREATES ALIAS REFERENCE
    [ $? -ne 0 ] && echo $BASH_SOURCE ERROR from local tag assignment && exit 1

    docker push $PUSH_REF
    [ $? -ne 0 ] && echo $BASH_SOURCE ERROR from pushing release version tag && exit 1

    echo "$BASH_SOURCE : Capturing fresh cryptographic RepoDigest..."
    REPO_DIGEST=$(docker inspect --format='{{index .RepoDigests 0}}' $PUSH_REF 2>/dev/null)
    echo "--------------------------------------------------------"
    echo " SUCCESSFUL PUSH TO DOCKER HUB"
    echo " Deployment reference: $REPO_DIGEST"
    echo "--------------------------------------------------------"
fi


if [[ "$arg" =~ inspect ]]; then
   docker inspect --format='{{json .Config.Labels}}' $NAM/$TAG | jq   # jq pretty prints json
   [ $? -ne 0 ] && echo $BASH_SOURCE - ERROR from inspect && exit 1
fi


if [[ "$arg" =~ look ]]; then
    docker run --gpus all -it --rm $NAM/$TAG /bin/bash
   [ $? -ne 0 ] && echo $BASH_SOURCE - ERROR from look && exit 1
fi

if [[ "$arg" =~ save ]]; then
   echo $BASH_SOURCE save to TGZPATH $TGZPATH
   docker save "$NAM/$TAG" | gzip > $TGZPATH
   [ $? -ne 0 ] && echo $BASH_SOURCE - ERROR from save && exit 1
fi

if [[ "$arg" =~ ls ]]; then
   echo $BASH_SOURCE ls TGZPATH $TGZPATH
   ls -alst $TGZPATH
   du -h $TGZPATH
fi

if [[ "$arg" =~ scp ]]; then
   scp $TGZPATH L:/hpcfs/juno/junogpu/blyth/
   [ $? -ne 0 ] && echo $BASH_SOURCE - ERROR from scp && exit 1
fi



exit 0
