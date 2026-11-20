#!/usr/bin/env bash

# Prints the JRE version of a JRE image, which is used as the first part of the
# image tag `<JRE version>.<build time>` (e.g., 21.0.13_9.202611120130).
#
# Usage: get_jre_version.sh CONTEXT
#
# CONTEXT is the directory that includes the Dockerfile, and its name must be
# the Java major version (e.g., jre/21 or jre-ubi/21).
#
# The release workflow (.github/workflows/jre-release-reusable.yaml) uses this
# script to decide the image tag. The CI (.github/workflows/jre-ci.yaml) also
# runs it in pull requests so that a Dockerfile from which the version cannot
# be taken is found before the merge.

set -e -o pipefail; [[ -n "$DEBUG" ]] && set -x

CONTEXT=${1%/}
if [[ -z "$CONTEXT" ]]; then
  echo "Usage: $0 CONTEXT" >&2
  exit 1
fi

DOCKERFILE="${CONTEXT}/Dockerfile"
if [[ ! -f "$DOCKERFILE" ]]; then
  echo "${DOCKERFILE} does not exist" >&2
  exit 1
fi

# Temurin based image: Use the tag of the base image.
#   FROM eclipse-temurin:21.0.13_9-jre-resolute@sha256:... -> 21.0.13_9
jre_version=$(sed -nE 's/^FROM[[:space:]]+eclipse-temurin:([0-9]+(\.[0-9]+)*_[0-9]+)-[^[:space:]]*.*$/\1/p' "$DOCKERFILE")

# UBI based image: Use the version of the OpenJDK RPM package.
# The RPM version is `<feature>.<interim>.<update>.<patch>.<build>`.
# The package name can include `-headless` and the epoch (`1:`).
#   java-21-openjdk-21.0.13.0.9-1.2.el10            -> 21.0.13_9
#   java-21-openjdk-headless-1:21.0.13.0.9-1.2.el10 -> 21.0.13_9
#   java-21-openjdk-21.0.13.1.9-1.2.el10            -> 21.0.13.1_9
if [[ -z "$jre_version" ]]; then
  jre_version=$(sed -nE 's/^.*[[:space:]]java-[0-9]+-openjdk(-headless)?-([0-9]+:)?([0-9]+\.[0-9]+\.[0-9]+)\.([0-9]+)\.([0-9]+)-[^[:space:]]+.*$/\3 \4 \5/p' "$DOCKERFILE" \
    | awk '{ if ($2 == "0") { print $1 "_" $3 } else { print $1 "." $2 "_" $3 } }')
fi

# This also fails if more than one version is found.
if [[ ! "$jre_version" =~ ^[0-9]+(\.[0-9]+)*_[0-9]+$ ]]; then
  echo "Failed to get the JRE version from ${DOCKERFILE}: '${jre_version}'" >&2
  exit 1
fi

# The directory name is the Java major version. Fail if the JRE in the
# Dockerfile is a different major version, because the image would be pushed
# with a tag of the wrong major version.
expected_major=$(basename "$CONTEXT")
actual_major="${jre_version%%[._]*}"
if [[ "$actual_major" != "$expected_major" ]]; then
  echo "The JRE version '${jre_version}' in ${DOCKERFILE} does not match the directory name '${expected_major}'" >&2
  exit 1
fi

echo "$jre_version"
