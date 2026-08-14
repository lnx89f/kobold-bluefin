# syntax=docker/dockerfile:1
# Kobold is a deliberately small downstream layer on top of Bluefin Standard.
# BASE_IMAGE is intentionally mandatory. scripts/resolve-base.sh resolves
# bluefin:stable to an immutable digest before any build starts.
ARG BASE_IMAGE
FROM ${BASE_IMAGE}

ARG KOBOLD_IMAGE_REGISTRY=ghcr.io
ARG KOBOLD_IMAGE_VENDOR=lnx89f
ARG KOBOLD_IMAGE_NAME=kobold
ARG KOBOLD_IMAGE_TAG=local

ENV KOBOLD_IMAGE_REGISTRY=${KOBOLD_IMAGE_REGISTRY} \
    KOBOLD_IMAGE_VENDOR=${KOBOLD_IMAGE_VENDOR} \
    KOBOLD_IMAGE_NAME=${KOBOLD_IMAGE_NAME} \
    KOBOLD_IMAGE_TAG=${KOBOLD_IMAGE_TAG}

COPY files/ /
COPY custom/flatpaks/ /etc/flatpak/preinstall.d/
COPY build/ /tmp/kobold-build/
COPY tests/ /tmp/kobold-tests/

RUN chmod 0755 /tmp/kobold-build/*.sh /tmp/kobold-tests/*.sh /usr/bin/divination

# Keep stages separate deliberately. Besides producing useful build diagnostics,
# Podman's layer cache preserves every successful stage when a later policy gate
# needs a small correction.
RUN echo '=== Kobold stage 10: packages ===' && /tmp/kobold-build/10-packages.sh
RUN echo '=== Kobold stage 20: services ===' && /tmp/kobold-build/20-services.sh
RUN echo '=== Kobold stage 30: desktop ===' && /tmp/kobold-build/30-desktop.sh
RUN echo '=== Kobold stage 40: virtualization ===' && /tmp/kobold-build/40-virtualization.sh
RUN echo '=== Kobold stage 50: security ===' && /tmp/kobold-build/50-security.sh
RUN echo '=== Kobold stage 60: branding ===' && /tmp/kobold-build/60-branding.sh
RUN echo '=== Kobold stage 90: validation ===' && /tmp/kobold-build/90-validate.sh
RUN rm -rf /tmp/kobold-build /tmp/kobold-tests

# bootc is the final structural gate for the bootable container. /run is
# runtime-only and bootc explicitly accepts it as a tmpfs during lint.
RUN --mount=type=tmpfs,target=/run --network=none \
    bootc container lint --fatal-warnings
