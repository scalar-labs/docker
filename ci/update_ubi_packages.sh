#!/usr/bin/env bash

# Updates the RPM packages pinned in the `microdnf install` command of a
# UBI-based Dockerfile to the latest versions available in the repositories of
# its base image. Dependabot cannot detect these versions, so
# .github/workflows/update-ubi-packages.yaml runs this script on a schedule.
#
# Usage: update_ubi_packages.sh DOCKERFILE
#
# The Dockerfile is updated in place. One line per updated package is printed
# to stdout in the form
# `<name> <old [epoch:]version-release> <new [epoch:]version-release>`.
# Nothing is printed if all the packages are already up to date.

set -e -o pipefail; [[ -n "$DEBUG" ]] && set -x

DOCKERFILE=$1
if [[ -z "$DOCKERFILE" ]]; then
  echo "Usage: $0 DOCKERFILE" >&2
  exit 1
fi

# Query the repositories from the pinned base image itself so that the result
# matches what `microdnf install` resolves when the image is built.
BASE_IMAGE=$(awk '$1 == "FROM" { print $2; exit }' "$DOCKERFILE")
if [[ -z "$BASE_IMAGE" ]]; then
  echo "Failed to read the base image from ${DOCKERFILE}" >&2
  exit 1
fi

# Collect the package arguments of `microdnf install`, skipping the options.
PINNED_PACKAGES=$(awk '
  {
    for (i = 1; i < NF; i++) {
      if ($i != "microdnf" || $(i + 1) != "install") continue
      for (j = i + 2; j <= NF; j++) {
        if ($j == "&&" || $j == "\\") break
        if ($j ~ /^-/) continue
        print $j
      }
    }
  }' "$DOCKERFILE")

PINS=()
NAMES=()
for pin in $PINNED_PACKAGES; do
  # Only packages pinned as <name>-[<epoch>:]<version>-<release> can be updated.
  if [[ ! "$pin" =~ ^.+-([0-9]+:)?[0-9][^-]*-[^-]+$ ]]; then
    echo "Skipping ${pin} because it is not pinned as <name>-[<epoch>:]<version>-<release>" >&2
    continue
  fi
  PINS+=("$pin")
  NAMES+=("${pin%-*-*}")
done

if [[ ${#PINS[@]} -eq 0 ]]; then
  echo "No pinned packages found in ${DOCKERFILE}" >&2
  exit 1
fi

# Each package is printed as <name>-[<epoch>:]<version>-<release>.<arch>.
AVAILABLE=$(docker run --rm "$BASE_IMAGE" microdnf repoquery --available "${NAMES[@]}")

content=$(<"$DOCKERFILE")
for i in "${!PINS[@]}"; do
  pin=${PINS[$i]}
  name=${NAMES[$i]}
  current=${pin#"${name}"-}

  # Split the pinned version into the epoch (optional) and <version>-<release>.
  current_epoch=""
  current_vr=$current
  if [[ "$current" =~ ^([0-9]+):(.+)$ ]]; then
    current_epoch=${BASH_REMATCH[1]}
    current_vr=${BASH_REMATCH[2]}
  fi

  # Print `<version>-<release> <epoch>` of each available package (`-` if it has
  # no epoch) and take the latest one.
  # Note that `sort -V` is not exactly the RPM version comparison, but it is
  # close enough for the version schemes of the packages we pin. The epoch is
  # not compared because we do not expect it to change.
  read -r latest_vr latest_epoch < <(awk -v name="$name" '
    {
      nevr = $1
      sub(/\.[^.]+$/, "", nevr)
      n = nevr
      sub(/-[^-]+-[^-]+$/, "", n)
      if (n != name) next
      vr = substr(nevr, length(n) + 2)
      epoch = "-"
      if (match(vr, /^[0-9]+:/)) {
        epoch = substr(vr, 1, RLENGTH - 1)
        vr = substr(vr, RLENGTH + 1)
      }
      print vr, epoch
    }' <<<"$AVAILABLE" | sort -V | tail -n 1) || true

  if [[ -z "$latest_vr" ]]; then
    echo "Failed to find ${name} in the repositories of ${BASE_IMAGE}" >&2
    exit 1
  fi

  newest=$(printf '%s\n' "$current_vr" "$latest_vr" | sort -V | tail -n 1)
  if [[ "$latest_vr" == "$current_vr" || "$newest" != "$latest_vr" ]]; then
    echo "${name} is up to date (pinned: ${current}, available: ${latest_vr})" >&2
    continue
  fi

  # Keep the epoch in the pin only if the current pin has it.
  new=$latest_vr
  if [[ -n "$current_epoch" ]]; then
    if [[ "$latest_epoch" != "-" ]]; then
      new="${latest_epoch}:${latest_vr}"
    else
      new="${current_epoch}:${latest_vr}"
    fi
  fi

  content=${content//"${pin}"/"${name}-${new}"}
  echo "${name} ${current} ${new}"
done

printf '%s\n' "$content" >"$DOCKERFILE"
