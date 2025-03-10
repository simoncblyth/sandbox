# https://docs.docker.com/reference/dockerfile/#automatic-platform-args-in-the-global-scope
ARG FROM_REF
FROM --platform=$BUILDPLATFORM $FROM_REF

ARG TARGETARCH
ARG TARGETOS
ARG TARGETPLATFORM

ARG BUILDARCH
ARG BUILDOS
ARG BUILDPLATFORM

RUN echo "FROM_REF       $FROM_REF"
RUN echo "TARGETPLATFORM $TARGETPLATFORM"
RUN echo "TARGETOS       $TARGETOS"
RUN echo "TARGETARCH     $TARGETARCH"

RUN echo "BUILDPLATFORM  $BUILDPLATFORM"
RUN echo "BUILDOS        $BUILDOS"
RUN echo "BUILDARCH      $BUILDARCH"


CMD echo $((40 + 2))


RUN dnf install -y https://ecsft.cern.ch/dist/cvmfs/cvmfs-release/cvmfs-release-latest.noarch.rpm \
  && dnf install -y cvmfs \
  && mkdir /etc/cvmfs/keys/ihep.ac.cn \
  && curl -o /etc/cvmfs/keys/ihep.ac.cn/ihep.ac.cn.pub http://cvmfs-stratum-one.ihep.ac.cn/cvmfs/software/client_configure/ihep.ac.cn/ihep.ac.cn.pub \
  && curl -o /etc/cvmfs/domain.d/ihep.ac.cn.conf http://cvmfs-stratum-one.ihep.ac.cn/cvmfs/software/client_configure/ihep.ac.cn.conf \
  && echo "CVMFS_REPOSITORIES='sft.cern.ch,juno.ihep.ac.cn,container.ihep.ac.cn'" | tee    /etc/cvmfs/default.local \
  && echo "CVMFS_HTTP_PROXY=DIRECT"                                               | tee -a /etc/cvmfs/default.local \
  && cat /etc/cvmfs/default.local \
  && mkdir -p /cvmfs/sft.cern.ch \
  && mkdir -p /cvmfs/juno.ihep.ac.cn \
  && mkdir -p /cvmfs/container.ihep.ac.cn;



RUN ls -alst /cvmfs/juno.ihep.ac.cn/


