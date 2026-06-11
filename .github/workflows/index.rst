.github/workflows/index
========================


Q: How to control with yml GHA will run ?
------------------------------------------



Actual docker use to create JUNOSW+Opticks image
-------------------------------------------------

junosw-build-docker-image-and-scp.yml
    build and scp junosw/Dockerfile-junosw-cuda-runtimeplus-el9 
    (looks to be preparation and testing for the next yml below)

simoncblyth-build-docker-image-and-push.yml
    build and push using junosw/Dockerfile-junosw-cuda-runtimeplus-el9
    [CAUTION : THIS PUSHES TO DOCKERHUB REGISTRY] 

simoncblyth-pull-docker-image-and-scp.yml
    pull and scp from dockhub the image created above 



More involved exercises getting to know the components needed for JUNOSW+Opticks image creation
---------------------------------------------------------------------------------------------------

cvmfs-build-docker-image-and-scp.yml
    build cvmfs/Dockerfile image making use of docker buildx FROM_REF flexibility,
    actually doesnt seems to generalize very much - given rarity of making
    docker images there is not much benefit from flexibility

nv-build-docker-image-and-scp.yml
    "docker buildx" builds nvidia standard image and scps the image somewhere
    configured via GH secrets

pull-docker-image-and-inspect.yml
    pull and inspect standard junosw image 

pull-docker-image-and-inspect-and-scp.yml
    pull and inspect standard junosw image then scp it

pull-docker-image-and-scp.yml
    pull rockylinux:9 save to tar and scp

pull-docker-image-and-scp-2.yml
    pull save and scp nvidia/cuda:12.4.1-devel-rockylinux9


Learning docker usage
-----------------------

build-docker-image-and-scp.yml
    testing docker and scp commands using a small "bb" busybox Dockerfile

learn-github-actions.yml
    npm installs "bats" : Bash Automated Testing System, looks like just some example

try-docker-container.yml
    checking GH VM usage

try-docker-build.yml
    bb/Dockerfile busybox build and save

try-docker-pull.yml
    docker run hello-world

try-docker-run-action.yml
    uses "addnab/docker-run-action@v3" suspect this approach means github lock in, so better to keep it simple

try-ssh-commands.yml
    scp exercises

try-vm-container.yml
    basics
