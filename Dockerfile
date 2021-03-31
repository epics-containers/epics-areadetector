# EPICS SynApps Dockerfile
ARG REGISTRY=gcr.io/diamond-privreg/controls/prod
ARG SYNAPPS_VERSION=6.2b4

FROM ${REGISTRY}/epics/epics-synapps:${SYNAPPS_VERSION}

ARG ADSUPPORT_VERSION=R1-9-1
ARG ADCORE_VERSION=R3-10

# install additional tools and libs
USER root

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
    libblosc-dev \
    libhdf5-dev \
    libjpeg-dev \
    libtiff-dev \
    libxml2-dev

# get additional support modules
USER ${USERNAME}

RUN ./add_module.sh areaDetector ADSupport ADSUPPORT ${ADSUPPORT_VERSION}
RUN ./add_module.sh areaDetector ADCore ADCORE ${ADCORE_VERSION}

# add CONFIG_SITE.linux and RELEASE.local
COPY --chown=1000 configure ${SUPPORT}/ADSupport-${ADSUPPORT_VERSION}/configure
COPY --chown=1000 configure ${SUPPORT}/ADCore-${ADCORE_VERSION}/configure

# update dependencies and build
RUN make release && \
    make -C ADSupport-${ADSUPPORT_VERSION} && \
    make -C ADCore-${ADCORE_VERSION} && \
    make clean

