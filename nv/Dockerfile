
# https://docs.docker.com/reference/dockerfile/#automatic-platform-args-in-the-global-scope
FROM --platform=$BUILDPLATFORM nvidia/cuda:12.4.1-devel-rockylinux9 

ARG TARGETARCH
ARG TARGETOS
ARG TARGETPLATFORM

ARG BUILDARCH
ARG BUILDOS
ARG BUILDPLATFORM


RUN echo "TARGETPLATFORM $TARGETPLATFORM"
RUN echo "TARGETOS       $TARGETOS"
RUN echo "TARGETARCH     $TARGETARCH"

RUN echo "BUILDPLATFORM  $BUILDPLATFORM"
RUN echo "BUILDOS        $BUILDOS"
RUN echo "BUILDARCH      $BUILDARCH"


CMD echo $((40 + 2))
CMD nvidia-smi


