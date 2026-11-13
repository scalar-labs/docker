# You can see sha256 hash in the following page:
# - https://hub.docker.com/_/eclipse-temurin/tags
FROM eclipse-temurin:21.0.13_9-jre-resolute@sha256:556903b1f40c0a0ddc0bd05cf413436a3b2ce48c9ee19fc199434898fd3ea2b9

RUN export DEBIAN_FRONTEND=noninteractive \
 && apt-get update \
 && apt-get upgrade -y --no-install-recommends \
 && apt-get autoremove -y \
 && rm -rf /var/lib/apt/lists/*

# The release workflow sets these values automatically.
# - IMAGE_NAME: Image name (e.g., jre21)
# - IMAGE_VERSION: JRE version (e.g., 21.0.13_9)
# - IMAGE_RELEASE: Build time in UTC (e.g., 202611120130)
ARG IMAGE_NAME=jre21
ARG IMAGE_VERSION
ARG IMAGE_RELEASE

LABEL name="${IMAGE_NAME}" \
      maintainer="Scalar, Inc." \
      vendor="Scalar, Inc." \
      version="${IMAGE_VERSION}" \
      release="${IMAGE_RELEASE}" \
      summary="Temurin based JRE 21 for Scalar products" \
      description="Temurin based JRE 21 for Scalar products"
