# You can see sha256 hash in the following page:
# - https://catalog.redhat.com/en/software/containers/ubi10/ubi-minimal/66f1504a379b9c2cf23e145c
FROM registry.access.redhat.com/ubi10/ubi-minimal:1793835006@sha256:cc3d766e796fbb50d6fcd599f4bad4c231aeae41822c6e86e7da664a996221ca

RUN microdnf update -y \
 && microdnf install java-25-openjdk-headless-1:25.0.5.0.8-1.0.el10 shadow-utils-4.15.0-13.el10 --setopt=install_weak_deps=0 --nodocs -y \
 && microdnf clean all \
 && rm -rf /var/cache/yum

# The release workflow sets these values automatically.
# - IMAGE_NAME: Image name (e.g., jre25-ubi)
# - IMAGE_VERSION: JRE version (e.g., 25.0.5_8)
# - IMAGE_RELEASE: Build time in UTC (e.g., 202611120130)
ARG IMAGE_NAME=jre25-ubi
ARG IMAGE_VERSION
ARG IMAGE_RELEASE

LABEL name="${IMAGE_NAME}" \
      maintainer="Scalar, Inc." \
      vendor="Scalar, Inc." \
      version="${IMAGE_VERSION}" \
      release="${IMAGE_RELEASE}" \
      summary="UBI based JRE 25 for Scalar products" \
      description="UBI based JRE 25 for Scalar products"
