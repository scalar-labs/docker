# You can see sha256 hash in the following page:
# - https://hub.docker.com/_/eclipse-temurin/tags
FROM eclipse-temurin:25.0.5_8-jre-resolute@sha256:480ef64e4540d45b0301e8afb7873bd3fa61ce93c5f66273eb569420718f38e2

RUN export DEBIAN_FRONTEND=noninteractive \
 && apt-get update \
 && apt-get upgrade -y --no-install-recommends \
 && apt-get autoremove -y \
 && rm -rf /var/lib/apt/lists/*

# The release workflow sets these values automatically.
# - IMAGE_NAME: Image name (e.g., jre25)
# - IMAGE_VERSION: JRE version (e.g., 25.0.5_8)
# - IMAGE_RELEASE: Build time in UTC (e.g., 202611120130)
ARG IMAGE_NAME=jre25
ARG IMAGE_VERSION
ARG IMAGE_RELEASE

LABEL name="${IMAGE_NAME}" \
      maintainer="Scalar, Inc." \
      vendor="Scalar, Inc." \
      version="${IMAGE_VERSION}" \
      release="${IMAGE_RELEASE}" \
      summary="Temurin based JRE 25 for Scalar products" \
      description="Temurin based JRE 25 for Scalar products"
