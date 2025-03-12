#!/bin/bash
usage(){ cat << EOU
docker-mock-gitlab-ci.sh:usage
===============================

Unfortunately "gitlab-runner exec" functionality for local workflow testing 
is removed from gitlab-runner 16.0::

    A[blyth@localhost ~]$ gitlab-runner exec
    Runtime platform                                    arch=amd64 os=linux pid=1674561 revision=bbf75488 version=17.9.1
    FATAL: Command exec not found.                     

    A[blyth@localhost ~]$ which gitlab-runner
    /usr/bin/gitlab-runner

    A[blyth@localhost ~]$ gitlab-runner -v
    Version:      17.9.1
    Git revision: bbf75488
    Git branch:   17-9-stable
    GO version:   go1.23.2 X:cacheprog
    Built:        2025-03-07T23:57:02Z
    OS/Arch:      linux/amd64


* https://gitlab.com/gitlab-org/gitlab/-/issues/385235

  "Deprecation of the gitlab-runner exec command from GitLab Runner"


This script provides a manual workaround to do similar 
to the old "gitlab-runner exec".

Usage:

* in one session start the base container with docker_run function

~/sandbox/docker-mock-gitlab-ci.sh run
    start container using "docker run", its 
    interactive to allow checking the build in progress 

* in another session run the payload within the container with docker_exec function

~/sandbox/docker-mock-gitlab-ci.sh exec
    performs the below *implicit* and *script* functions within the container started above. 
    The payload function invokes the junosw build.sh script 


This script allows candidate modifications to the CI workflow to be tested 
without needing to change junosw/.gitlab-ci.yml and without needing 
lots of pushes to trigger CI builds.

The kind of changes to be tested:

1. changing the base docker image to one that includes CUDA
2. doing junosw+opticks build by setting OPTICKS_PREFIX to point
   to an Opticks release on /cvmfs/opticks.ihep.ac.cn/  

EOU
}


info(){ cat << EOI
docker-mock-gitlab-ci.sh:info
================================

   docker_ref : $(docker_ref)
   docker_nam : $(docker_nam)


+--------------+-----------+----------------------+
| nam          | size      |  notes               |
+==============+===========+======================+
| base         |   2.51GB  |  no CUDA             |
+--------------+-----------+----------------------+
| runtime      |   5.81GB  |  misses headers      |
+--------------+-----------+----------------------+
| runtimeplus  |   8.88GB  |  cherrypick devel    |      
+--------------+-----------+----------------------+
| devel        |  >10GB ?  |                      | 
+--------------+-----------+----------------------+


EOI
}


defarg=script
arg=${1:-$defarg}



#docker_nam(){ echo base ; }           
#docker_nam(){ echo runtime ; }       
docker_nam(){ echo runtimeplus ; }   
#docker_nam(){ echo devel ; }       

docker_ref(){  echo junosw/cuda:12.4.1-$(docker_nam)-rockylinux9 ; }


docker_run_opts(){ 
   local ref=$(docker_ref)
   if [ "${ref/cuda}" != "$ref" ]; then
      cat << EOO
         --runtime=nvidia --gpus=all
EOO
   else
       echo -n
   fi 
}


docker_run()
{
   : docker_run - starting container with mounts from host into container 
   type $FUNCNAME
   docker run --rm -it \
      $(docker_run_opts) \
      --name $(docker_nam) \
      --mount type=bind,source=/cvmfs,target=/cvmfs,ro \
      --mount type=bind,source=$HOME/junosw,target=/home/juno/junosw \
      $(docker_ref) 

   docker ps -a
}
docker_exec()
{
   : docker_exec this script with defarg script doing implicit+script with bash in the container 
   type $FUNCNAME
   docker ps -a
   docker exec -i $(docker_nam) bash < $BASH_SOURCE  
}

implicit()
{
    : implicitly done by gitlab-ci

    pwd
    sudo chown -R juno:juno junosw
    cd junosw       ## thats where the .gitlab-ci.yml is
    pwd
}

script()
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
  usage|h) usage ;;
  info) info ;;
  run) docker_run ;;
  exec) docker_exec ;;
  script) implicit ; script ;; 
esac

