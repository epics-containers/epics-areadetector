# EPICS ADCore Dockerfile
# Adds the Area Detector base support required by all AD images
ARG REGISTRY=ghcr.io/epics-containers
ARG MODULES_VERSION=4.41r1.0

FROM ${REGISTRY}/epics-modules:${MODULES_VERSION}

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

USER ${USERNAME}

# get additional support modules
ARG ADSUPPORT_VERSION=R1-9-1
ARG ADCORE_VERSION=R3-10

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

