#!/bin/bash
usage(){ cat << EOU
docker-mock-gitlab-ci.sh:usage
===============================

Unfortunately "gitlab-runner exec" local running functionality 
has been removed since gitlab-runner 16.0

This script provides a manual workaround for that, using two sessions: 

"docker run" 
    start a container, interactively for checking the build in progress 

"docker exec" 
    perform the below *prepare* and *payload* 
    functions within the container started above. 
    The payload function invokes the junosw build.sh script 


Thus this script allows candidate modifications to the CI workflow 
to be tested without needing to change junosw/.gitlab-ci.yml 
and without needing lots of pushes to trigger CI builds.

The kind of changes to be tested:

1. changing the base docker image to one that includes CUDA
2. doing junosw+opticks build by setting OPTICKS_PREFIX to point
   to an Opticks release on /cvmfs/opticks.ihep.ac.cn/  

Usage:

* in one session start the base container with docker_run function::

   ~/sandbox/docker-mock-gitlab-ci.sh r
   
In another session run the payload within the container with docker_exec function::

   ~/sandbox/docker-mock-gitlab-ci.sh e

EOU
}


info(){ cat << EOI
docker-mock-gitlab-ci.sh:info
================================

   docker_ref : $(docker_ref)
   docker_nam : $(docker_nam)

EOI
}


defarg=p
arg=${1:-$defarg}

docker_ref(){  echo junosw/base:el9 ; }
docker_nam(){ echo jel9 ; }

docker_run()
{
   : docker run - starting container with mounts from host into container 
   type $FUNCNAME
   docker run --rm -it \
      --name $(docker_nam) \
      --mount type=bind,source=/cvmfs,target=/cvmfs,ro \
      --mount type=bind,source=$HOME/junosw,target=/home/juno/junosw \
      $(docker_ref) 

   docker ps -a
}
docker_exec()
{
   : docker exec this script with defarg p doing prepare and payload with bash in the container 
   type $FUNCNAME
   docker exec -i $(docker_nam) bash < $BASH_SOURCE  
}

prepare()
{
    : implicitly done by gitlab-ci

    pwd
    sudo chown -R juno:juno junosw
    cd junosw       ## thats where the .gitlab-ci.yml is
    pwd
}

payload()
{
    : equivalent to the script block of junosw/.gitlab-ci.yml

    sudo mount -t cvmfs juno.ihep.ac.cn /cvmfs/juno.ihep.ac.cn
    #export JUNOTOP=/cvmfs/juno.ihep.ac.cn/el9_amd64_gcc11/Release/Jlatest
    export JUNOTOP=/cvmfs/juno.ihep.ac.cn/el9_amd64_gcc11/Release/J25.2.3
    export JUNO_CLANG_PREFIX
    export EXTRA_BUILD_FLAGS
    export JUNO_OFFLINE_OFF=1
    env | grep JUNO
    source $JUNOTOP/setup.sh
    if [ -n "$JUNO_CLANG_PREFIX" ]; then source $JUNO_CLANG_PREFIX/bashrc; fi
    env $EXTRA_BUILD_FLAGS ./build.sh
}

case $arg in 
  u) usage ;;
  i) info ;;
  r) docker_run ;;
  e) docker_exec ;;
  p) prepare ; payload ;; 
esac

