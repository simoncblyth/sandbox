#!/bin/bash
usage(){ cat << EOU
docker-mock-gitlab-ci.sh:usage
===============================

NB the docker image tested here is created by local/build.sh

TLDR::

    ~/sandbox/docker-mock-gitlab-ci.sh run    ## SPIN UP THE CONTAINER
    ~/sandbox/docker-mock-gitlab-ci.sh clean  ## REMOVE LOCAL DIRS ~/junosw/build/\$branch ~/junosw/InstallArea/\$branch
    ~/sandbox/docker-mock-gitlab-ci.sh exec   ## RUN THE MOCK GITLAB-CI BUILD IN THE CONTAINER


Usage
-------

This script allows JUNOSW+Opticks docker images/containers to be tested BEFORE
pushing them to hub.docker.com and using them from gitlab-ci

This script allows candidate modifications to the CI workflow to be tested
without needing to change ~/junosw/.gitlab-ci.yml and without needing
lots of pushes to trigger CI builds.

The kind of changes to be tested:

1. changing the base docker image to one that includes CUDA
2. doing junosw+opticks build by setting OPTICKS_PREFIX to point
   to an Opticks release on /cvmfs/opticks.ihep.ac.cn/


Details
--------

More specifically this script provides a way to test a build using the environment created
from a docker image to provide externals but using local directories::

   ~/junosw
   ~/junosw/build/$branch
   ~/junosw/InstallArea/$branch



Start base container using "docker run"::

    ~/sandbox/docker-mock-gitlab-ci.sh run
    GPU=1 ~/sandbox/docker-mock-gitlab-ci.sh run

Setting GPU gives access within the container to the hosts GPU
as provided by nvidia_container_toolkit package
This is needed for testing, but not building.

To force full(and slow) build do a clean::

   ~/sandbox/docker-mock-gitlab-ci.sh clean

Invoke the build via "docker exec" with::

   ~/sandbox/docker-mock-gitlab-ci.sh exec




About former "gitlab-runner exec" functionality that this script mimicks
--------------------------------------------------------------------------

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
#docker_nam(){ echo runtimeplus ; }
#docker_nam(){ echo devel ; }

docker_nam(){  echo from-junosw-test ; }


#docker_ref(){  echo junosw/cuda:12.4.1-$(docker_nam)-rockylinux9 ; }

#docker_ref(){  echo simoncblyth/cuda:12.4.1-$(docker_nam)-rockylinux9 ; }
docker_ref(){  echo simoncblyth/junosw:el9.4-cuda13.1-opticks ; }


#docker_opticks_prefix(){ echo /cvmfs/opticks.ihep.ac.cn/ok/releases/Opticks-v0.2.1/x86_64-CentOS7-gcc1120-geant4_10_04_p02-dbg ; }
#docker_opticks_prefix(){ echo /cvmfs/opticks.ihep.ac.cn/ok/releases/Opticks-v0.3.1/x86_64--gcc11-geant4_10_04_p02-dbg ; }
#docker_opticks_prefix(){ echo /data1/blyth/local/opticks_Debug/Opticks-v0.3.1/x86_64--gcc11-geant4_10_04_p02-dbg ; }
#docker_opticks_prefix(){ echo /data1/blyth/local/opticks_Debug/Opticks-v0.3.3/x86_64--gcc11-geant4_10_04_p02-dbg ; }
docker_opticks_prefix(){  echo /cvmfs/opticks.ihep.ac.cn/ok/releases/el9_amd64_gcc11/Opticks-v0.6.5 ; }

docker_opticks_prefix_notes(){ cat << EON
OPTICKS_PREFIX configures which Opticks to use for the JUNOSW+Opticks build being tested

* Standard gitlab CI/CD uses OPTICKS_PREFIX from /cvmfs/opticks.ihep.ac.cn releases
* For local workstation tests it is convenient to mount a local path avoiding
  the step of doing the /cvmfs release


EON
}


docker_run_opts(){

   : building should not need GPU access but testing will
   if [ -n "$GPU" ]; then
      cat << EOO
         --runtime=nvidia --gpus=all
EOO
   else
       echo -n
   fi
}


docker_run_notes(){ cat << EON

The eg "--user 1002:1002" option enables the user from the host to be effectively used
from inside the container.  Without this it was necessary to "sudo chmod" to change ownership
of files on host written by container processes.
But a side effect is that the host user is likely unknown inside the container leading to
the HOME envvar being set to "/" - that tickles a geant4-config bug resulting in broken prefix
path.

EON
}

docker_run()
{
   : docker_run - starting container with mounts from host into container
   type $FUNCNAME

   info

   local dop=$(docker_opticks_prefix)
   : dop docker_opticks_prefix mount only needed for fast cycle debug

   local host_user_id="$(id -u):$(id -g)"

   docker run --rm -it \
      $(docker_run_opts) \
      --name $(docker_nam) \
      --user "$host_user_id" \
      -v /cvmfs/juno.ihep.ac.cn:/cvmfs/juno.ihep.ac.cn:ro \
      -v /cvmfs/opticks.ihep.ac.cn:/cvmfs/opticks.ihep.ac.cn:ro \
      -v $HOME/junosw:/junosw \
      -v $dop:$dop \
      $(docker_ref)

   docker ps -a
}
docker_exec()
{
   : docker_exec this script with defarg script which invokes the below function within the container
   type $FUNCNAME
   docker ps -a
   docker exec -i $(docker_nam) bash < $BASH_SOURCE
}








local_clean()
{
    : use-for-clean-build-test-caution-slow
    cd ~/junosw
    local branch=$(git branch --show-current)
    if [ -n "$branch" ]; then
        if [ -d "build/$branch" ]; then
            echo $FUNCNAME - removing build/$branch
            rm -rf build/$branch
        fi
        if [ -d "InstallArea/$branch" ]; then
            echo $FUNCNAME - removing build/$branch
            rm -rf InstallArea/$branch
        fi
    fi
}

local_script()
{
    : equivalent to the script block of junosw/.gitlab-ci.yml
    type $FUNCNAME

    export HOME=/junosw  # HOME being "/" messes up geant4-config path mechanics
    export JUNO_OFFLINE_BUILD_BRANCH=1  ## use build/$branch InstallArea/$branch

    export JUNO_OPTICKS_PREFIX=$(docker_opticks_prefix)
    export JUNOTOP=/cvmfs/juno.ihep.ac.cn/el9_amd64_gcc11/Release/Jlatest

    export JUNO_CLANG_PREFIX

    export EXTRA_BUILD_FLAGS="JUNO_CMAKE_BUILD_TYPE=Debug"
    export JUNO_OFFLINE_OFF=1
    env | grep JUNO
    source $JUNOTOP/setup.sh
    if [ -n "$JUNO_CLANG_PREFIX" ]; then source $JUNO_CLANG_PREFIX/bashrc; fi
    if [ -n "$JUNO_OPTICKS_PREFIX" ]; then source $JUNO_OPTICKS_PREFIX/bashrc ; fi

    cd /junosw
    env $EXTRA_BUILD_FLAGS ./build.sh
}

case $arg in
  usage|h) usage ;;
  info) info ;;
  run) docker_run ;;
  exec) docker_exec ;;
  clean) local_clean ;;
  script) local_script ;;
esac

