
index of Dockerfiles
========================


original
----------

Dockerfile-junosw-base-el9
    "FROM almalinux:9" with dnf setup of base externals for JUNOSW and cvmfs setup


runtime 
--------

Dockerfile-junosw-cuda-runtime-el9
    Very similar to above "Dockerfile-junosw-base-el9" but "FROM nvidia/cuda:12.4.1-runtime-rockylinux9" 
    with small changes for differences between almalinux:9 and rockylinux9

Dockerfile-junosw-cuda-runtime-el9-check
    As above but with dnf install lines split to allow identification of problems 


runtimeplus : plus some devel pkgs, but not all to stay lite and within github quota
----------------------------------------------------------------------------------------

Dockerfile-junosw-cuda-runtimeplus-el9
    Documented Dockerfile inbetween the NVIDIA standard "runtime" and "devel" 
    together with the JUNOSW dnf setup basis packages and cvmfs config.

Dockerfile-junosw-cuda-runtimeplus-el9-check
    As above but with dnf install lines split to allow identification of problems 



