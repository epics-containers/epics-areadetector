# EPICS SynApps Dockerfile
ARG REGISTRY=gcr.io/diamond-privreg/controls/prod
ARG SYNAPPS_VERSION=6.2b1.1

FROM ${REGISTRY}/epics/epics-synapps:${SYNAPPS_VERSION}

# install additional tools and libs
USER root

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
    libblosc-dev \
    libhdf5-dev \
    libjpeg-dev \
    libtiff-dev \
    libxml2-dev \
    pkg-config \
    p7zip-full \
    xz-utils

# get additional support modules
USER ${USERNAME}

ARG ADSUPPORT_VERSION=R1-9-1
ARG ADCORE_VERSION=R3-10
ARG ADZMQ_VERSION=1-1-2
ARG ADZMQ_BRANCH=1.1.2
ARG FFMPEG_SRV_VERSION=replace_zeranoe_linux_only

RUN ./add_module.sh areaDetector ADSupport ADSUPPORT ${ADSUPPORT_VERSION}
RUN ./add_module.sh areaDetector ADCore ADCORE ${ADCORE_VERSION}
RUN ./add_module.sh paulscherrerinstitute ADZMQ ADZMQ ${ADZMQ_BRANCH}

# add CONFIG_SITE.linux and RELEASE.local
COPY --chown=1000 configure ${SUPPORT}/ADSupport-${ADSUPPORT_VERSION}/configure
COPY --chown=1000 configure ${SUPPORT}/ADCore-${ADCORE_VERSION}/configure
COPY --chown=1000 configure/RELEASE.local ${SUPPORT}/ADZMQ-${ADZMQ_VERSION}/configure

# update dependencies and build
RUN make release && \
    make -C ADSupport-${ADSUPPORT_VERSION} && \
    make -C ADCore-${ADCORE_VERSION} && \
    make -C ADZMQ-${ADZMQ_VERSION} && \
    make clean

RUN ./add_module.sh controls/support ffmpegServer FFMPEGSERVER ${FFMPEG_SRV_VERSION} gitlab.diamond.ac.uk
COPY --chown=1000 configure/RELEASE.local ${SUPPORT}/ffmpegServer-${FFMPEG_SRV_VERSION}/configure

RUN make release && \
    ffmpegServer-${FFMPEG_SRV_VERSION}/install.sh && \
    make -C ffmpegServer-${FFMPEG_SRV_VERSION}/vendor && \
    make -C ffmpegServer-${FFMPEG_SRV_VERSION} && \
    make clean -C ffmpegServer-${FFMPEG_SRV_VERSION}
