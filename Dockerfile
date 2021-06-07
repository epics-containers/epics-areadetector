# EPICS ADCore Dockerfile
# Adds the Area Detector base support required by all AD images
ARG REGISTRY=gcr.io/diamond-pubreg/controls/prod
ARG MODULES_VERSION=1.0

FROM ${REGISTRY}/epics/epics-modules:${MODULES_VERSION}

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
    xz-utils \
    && rm -rf /var/lib/apt/lists/*

# get additional support modules
USER ${USERNAME}

ARG ADSUPPORT_VERSION=R1-9-1
ARG ADCORE_VERSION=R3-10
ARG FFMPEG_SRV_VERSION=replace_zeranoe_linux_only

RUN python3 module.py add areaDetector ADSupport ADSUPPORT ${ADSUPPORT_VERSION}
RUN python3 module.py add areaDetector ADCore ADCORE ${ADCORE_VERSION}

# add CONFIG_SITE.linux and RELEASE.local
COPY --chown=${USER_UID}:${USER_GID} configure ${SUPPORT}/ADSupport-${ADSUPPORT_VERSION}/configure
COPY --chown=${USER_UID}:${USER_GID} configure ${SUPPORT}/ADCore-${ADCORE_VERSION}/configure

# update dependencies and build
RUN python3 module.py dependencies
RUN make -C ADSupport-${ADSUPPORT_VERSION} && \
    make -C ADCore-${ADCORE_VERSION} && \
    make clean

# fetch ffmpegserver (used for streaming images from AD pipeline)
RUN python3 module.py add controls/support ffmpegServer FFMPEGSERVER ${FFMPEG_SRV_VERSION} gitlab.diamond.ac.uk
COPY --chown=${USER_UID}:${USER_GID} configure/RELEASE.local ${SUPPORT}/ffmpegServer-${FFMPEG_SRV_VERSION}/configure
RUN python3 module.py dependencies

# build ffmpegserver
RUN ffmpegServer-${FFMPEG_SRV_VERSION}/install.sh && \
    make -C ffmpegServer-${FFMPEG_SRV_VERSION}/vendor && \
    make -C ffmpegServer-${FFMPEG_SRV_VERSION} && \
    make clean -C ffmpegServer-${FFMPEG_SRV_VERSION}
