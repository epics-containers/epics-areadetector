# EPICS ADCore Dockerfile
# Adds the Area Detector base support required by all AD images
ARG REGISTRY=ghcr.io/epics-containers
ARG MODULES_VERSION=4.41r1.1

FROM ${REGISTRY}/epics-modules:${MODULES_VERSION}

# install additional tools and libs
USER root

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
    curl \
    libblosc-dev \
    libhdf5-dev \
    libjpeg-dev \
    libtiff-dev \
    libxml2-dev \
    pkg-config \
    p7zip-full \
    xz-utils \
    && rm -rf /var/lib/apt/lists/*

# add the kafka client library
RUN curl -L https://github.com/edenhill/librdkafka/archive/v1.7.0.tar.gz | tar xzf - && \
    cd librdkafka-1.7.0/ && \
    ./configure --prefix=/usr && \
    make -j && \
    make install

USER ${USERNAME}

# get additional support modules
ARG ADSUPPORT_VERSION=R1-9-1
ARG ADCORE_VERSION=R3-10
ENV ADKAFKA_VERSION=0.1
ENV ADKAFKA_DIR=${SUPPORT}/ADKafka-0-1

RUN python3 module.py add areaDetector ADSupport ADSUPPORT ${ADSUPPORT_VERSION}
RUN python3 module.py add areaDetector ADCore ADCORE ${ADCORE_VERSION}
RUN python3 module.py add dls-controls ADKafka ADKAFKA ${ADKAFKA_VERSION}

# add CONFIG_SITE.linux and RELEASE.local
COPY --chown=${USER_UID}:${USER_GID} configure ${SUPPORT}/ADSupport-${ADSUPPORT_VERSION}/configure
COPY --chown=${USER_UID}:${USER_GID} configure ${SUPPORT}/ADCore-${ADCORE_VERSION}/configure
COPY --chown=${USER_UID}:${USER_GID} configure ${ADKAFKA_DIR}/configure

# update dependencies and build
RUN python3 module.py dependencies
RUN make -j -C  ${SUPPORT}/ADSupport-${ADSUPPORT_VERSION} && \
    make -j -C  ${SUPPORT}/ADCore-${ADCORE_VERSION} && \
    make -j -C  ${ADKAFKA_DIR} && \
    make -j clean

# add ffmpegserver for streaming detector images to an mpeg viewer
ENV FFMPEG_SRV_VERSION=linux-vendor
RUN python3 module.py add areaDetector ffmpegServer FFMPEGSERVER ${FFMPEG_SRV_VERSION}
COPY --chown=${USER_UID}:${USER_GID} configure ${SUPPORT}/ffmpegServer-${FFMPEG_SRV_VERSION}/configure
RUN python3 module.py dependencies

# build ffmpegserver
RUN ffmpegServer-${FFMPEG_SRV_VERSION}/install.sh && \
    make -C ffmpegServer-${FFMPEG_SRV_VERSION}/vendor && \
    make -C ffmpegServer-${FFMPEG_SRV_VERSION} && \
    make clean -C ffmpegServer-${FFMPEG_SRV_VERSION}