# EPICS ADCore Dockerfile
# Adds the Area Detector base support required by all AD images
ARG ADSUPPORT_VERSION=R1-9-1
ARG ADCORE_VERSION=R3-12-1

##### build stage ##############################################################

FROM ghcr.io/epics-containers/epics-modules:1.0.0 AS developer

ARG ADSUPPORT_VERSION
ARG ADCORE_VERSION

# get additional support modules
RUN python3 module.py add areaDetector ADSupport ADSUPPORT ${ADSUPPORT_VERSION}
RUN python3 module.py add areaDetector ADCore ADCORE ${ADCORE_VERSION}

# add CONFIG_SITE.linux and RELEASE.local
COPY configure ${SUPPORT}/ADSupport-${ADSUPPORT_VERSION}/configure
COPY configure ${SUPPORT}/ADCore-${ADCORE_VERSION}/configure

# update dependencies and build
RUN python3 module.py dependencies
RUN make -j -C  ${SUPPORT}/ADSupport-${ADSUPPORT_VERSION} && \
    make -j -C  ${SUPPORT}/ADCore-${ADCORE_VERSION} && \
    make -j clean

##### runtime stage ############################################################

FROM ghcr.io/epics-containers/epics-modules:1.0.0.run AS runtime

ARG ADSUPPORT_VERSION
ARG ADCORE_VERSION

# get the products from the build stage
COPY --from=developer ${SUPPORT}/ADSupport-${ADSUPPORT_VERSION} ${SUPPORT}/ADSupport-${ADSUPPORT_VERSION}
COPY --from=developer ${SUPPORT}/ADCore-${ADCORE_VERSION} ${SUPPORT}/ADCore-${ADCORE_VERSION}
