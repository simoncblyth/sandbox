#!/bin/sh

usage(){ cat << EOU
disable_all.sh
==============

Currently rely on manually disabling all the workflows 
in the github actions web interface at:

* https://github.com/simoncblyth/sandbox/actions


Running this script changes the yml to avoid needing
this manual web interface approach by replacing::

    on: [push]

with::

    on:
       workflow_dispatch:



That means that when not disabled in the web interface, a control
will be surfaced that allows manually running the workflows.

EOU
}

sed -i 's/on: \[push\]/on:\n  workflow_dispatch:/g' *.yml
