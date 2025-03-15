#!/bin/bash
usage(){ cat << EOU
docker-mock-gitlab-ci.sh:usage
===============================

TLDR::

    ~/sandbox/docker-mock-gitlab-ci.sh run

    cd ~/junosw && sudo rm -rf build InstallArea  ## for clean build test 

    ~/sandbox/docker-mock-gitlab-ci.sh exec



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
    start container using "docker run", it is interactive 
    to allow checking the build in progress 

GPU=1 ~/sandbox/docker-mock-gitlab-ci.sh run
    setting GPU gives access within the container to the hosts GPU 
    as provided by nvidia_container_toolkit package
    This is needed for testing, but not building. 

* in another session run the payload within the container with docker_exec function

To force full build on host::

   cd ~/junosw
   sudo rm -rf build InstallArea

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


Issues
--------

1. currently are chown changing host user/group of junosw to juno:juno in implicit_bef
   and changing back to again in implicit_aft 

   * thats ugly, better way ? 


EOU
}


info(){ cat << EOI
docker-mock-gitlab-ci.sh:info
================================

   docker_ref : $(docker_ref)
   docker_nam : $(docker_nam)

   docker_opticks_prefix : $(docker_opticks_prefix)   
      ## non /cvmfs for debug only 

EOI
}

notes(){ cat << EON

+--------------+-----------+------------------------------------+
| nam          | size      |  notes                             |
+==============+===========+====================================+
| base         |   2.51GB  |  no CUDA                           |
+--------------+-----------+------------------------------------+
| runtime      |   5.81GB  |  misses headers                    |
+--------------+-----------+------------------------------------+
| runtimeplus  |   7.5GB   |  cherrypick devel                  |      
+--------------+-----------+------------------------------------+
| devel        |  10GB+?   |  might be too big for GHA VM  ?    | 
+--------------+-----------+------------------------------------+



EON
}

defarg=script
arg=${1:-$defarg}

#docker_nam(){ echo base ; }           
#docker_nam(){ echo runtime ; }       
docker_nam(){ echo runtimeplus ; }   
#docker_nam(){ echo devel ; }       

docker_ref(){  echo junosw/cuda:12.4.1-$(docker_nam)-rockylinux9 ; }


#docker_opticks_prefix(){ echo /cvmfs/opticks.ihep.ac.cn/ok/releases/Opticks-v0.2.1/x86_64-CentOS7-gcc1120-geant4_10_04_p02-dbg ; }
#docker_opticks_prefix(){ echo /cvmfs/opticks.ihep.ac.cn/ok/releases/Opticks-v0.3.1/x86_64--gcc11-geant4_10_04_p02-dbg ; }
docker_opticks_prefix(){ echo /data1/blyth/local/opticks_Debug/Opticks-v0.3.1/x86_64--gcc11-geant4_10_04_p02-dbg ; }   ## for faster cycle debug


docker_run_opts(){ 

   : building should not need GPU access but testing will
   local ref=$(docker_ref)

   #if [ "${ref/cuda}" != "$ref" ]; then
   if [ -n "$GPU" ]; then
      cat << EOO
         --runtime=nvidia --gpus=all
EOO
   else
       echo -n
   fi 
}


docker_run_notes(){ cat << EON

      --mount type=bind,source=$dop,target=$dop,ro \

EON
}

docker_run()
{
   : docker_run - starting container with mounts from host into container 
   type $FUNCNAME

   info

   local dop=$(docker_opticks_prefix)  
   : dop mount only needed for fast cycle debug

   docker run --rm -it \
      $(docker_run_opts) \
      --name $(docker_nam) \
      --mount type=bind,source=/cvmfs/juno.ihep.ac.cn,target=/cvmfs/juno.ihep.ac.cn,ro \
      --mount type=bind,source=/cvmfs/opticks.ihep.ac.cn,target=/cvmfs/opticks.ihep.ac.cn,ro \
      --mount type=bind,source=$HOME/junosw,target=/home/juno/junosw \
      --volume $dop:$dop \
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

implicit_bef()
{
    : implicitly done by gitlab-ci

    type $FUNCNAME
    pwd
    sudo chown -R juno:juno junosw
    cd junosw       ## thats where the .gitlab-ci.yml is
    pwd
}
implicit_aft()
{
    local uid=$(id -nu)
    local gid=$(id -ng)
    cd  
    sudo chown -R $uid:$gid junosw
}

script()
{
    : equivalent to the script block of junosw/.gitlab-ci.yml
    type $FUNCNAME

    #sudo mount -t cvmfs juno.ihep.ac.cn /cvmfs/juno.ihep.ac.cn
    #sudo mount -t cvmfs opticks.ihep.ac.cn /cvmfs/opticks.ihep.ac.cn
    export OPTICKS_PREFIX=$(docker_opticks_prefix)

    #export JUNOTOP=/cvmfs/juno.ihep.ac.cn/el9_amd64_gcc11/Release/Jlatest
    export JUNOTOP=/cvmfs/juno.ihep.ac.cn/el9_amd64_gcc11/Release/J25.2.3
    export JUNO_CLANG_PREFIX

    export EXTRA_BUILD_FLAGS
    export JUNO_OFFLINE_OFF=1
    env | grep JUNO
    source $JUNOTOP/setup.sh
    if [ -n "$JUNO_CLANG_PREFIX" ]; then source $JUNO_CLANG_PREFIX/bashrc; fi
    if [ -n "$OPTICKS_PREFIX" ]; then 
         echo [ source $OPTICKS_PREFIX/bashrc
         source $OPTICKS_PREFIX/bashrc
         echo ] source $OPTICKS_PREFIX/bashrc
    else
         echo NOT with OPTICKS_PREFIX
    fi

    env $EXTRA_BUILD_FLAGS ./build.sh
}

case $arg in 
  usage|h) usage ;;
  info) info ;;
  run) docker_run ;;
  exec) docker_exec ;;
  script) implicit_bef ; script ; implicit_aft  ;; 
esac

