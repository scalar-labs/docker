# Docker images for Scalar products

This repository contains the Dockerfiles of the base images that Scalar products use.

This document describes how to maintain the JRE images. For the other images, see [Other images](#other-images).

## JRE images

| Directory | Image | Base |
| --- | --- | --- |
| `jre/21` | `ghcr.io/scalar-labs/jre21` | `eclipse-temurin` (JRE 21) |
| `jre/25` | `ghcr.io/scalar-labs/jre25` | `eclipse-temurin` (JRE 25) |
| `jre-ubi/21` | `ghcr.io/scalar-labs/jre21-ubi` | `ubi10/ubi-minimal` + `java-21-openjdk-headless` |
| `jre-ubi/25` | `ghcr.io/scalar-labs/jre25-ubi` | `ubi10/ubi-minimal` + `java-25-openjdk-headless` |

The image tag is `<JRE version>.<build time>`, for example `21.0.13_9.202611120130`.

- The JRE version comes from the Dockerfile. See [ci/get_jre_version.sh](./ci/get_jre_version.sh).
  - `jre/*`: The version in the tag of the `eclipse-temurin` image. For example, `eclipse-temurin:21.0.13_9-jre-resolute` becomes `21.0.13_9`.
  - `jre-ubi/*`: The version of the pinned OpenJDK package, which is `<feature>.<interim>.<update>.<patch>.<build>`. For example, `21.0.13.0.9` becomes `21.0.13_9`, and `21.0.13.1.9` becomes `21.0.13.1_9`. The release of the package (for example, `-1.2.el10`) is not in the tag.
- The build time is `YYYYMMDDhhmm` in UTC. It is the time when the release workflow runs, not the time of the commit.
- The `latest` tag is not pushed.

A release never overwrites or removes the existing tags. It only adds a new tag.

### What the images include

- The images are built for `linux/amd64` and `linux/arm64`.
- The OS packages are updated to the latest versions when the image is built (`apt-get upgrade` or `microdnf update`).
- The UBI based images also include `shadow-utils`.
- The images have no `USER` instruction, so the default user is `root`. The products that use the images must set the user.
- The images have the labels `name`, `version` (the JRE version), and `release` (the build time). The release workflow sets them with build arguments, so `version` and `release` are empty in an image that is built without them (for example, a local build).

### How to use the images

Pin both the tag and the digest in the `FROM` instruction, and let Dependabot update them.

```dockerfile
FROM ghcr.io/scalar-labs/jre21:21.0.13_9.202611120130@sha256:<digest>
```

- The summary of each run of the release workflow shows the `FROM` instruction of the released image, including the digest.
- Dependabot (`package-ecosystem: "docker"`) updates the tag and the digest together when a newer tag is released.

### Rules for the image tag

The repositories that use the images rely on Dependabot to compare the tags, so keep the following. Check how Dependabot handles the tags (the `docker` ecosystem of [dependabot-core](https://github.com/dependabot/dependabot-core)) before changing any of them.

- **Join the JRE version and the build time with `.`, and use only digits in the build time.** Dependabot compares the build time as a number. If the tag has a part that starts with a letter after `-` (for example, `21.0.13_9-r202611120130`), Dependabot treats the part as a suffix and only compares the tags that have the same suffix, so it finds no update.
- **Keep the build time a fixed-width number.** A build time with fewer digits is smaller as a number, so Dependabot does not treat it as a newer version.
- **Do not push the `latest` tag unless every release updates it.** Dependabot treats the tags that are newer than `latest` as pre-releases and ignores them.
- **Do not put the images of multiple Java major versions in one image name.** Dependabot would propose the update to the newer major version.
- **Do not delete the released images from `ghcr.io`.** The repositories that use them pin the digest, so their builds fail if the image is deleted.

## How the images are updated and released

1. A pull request that updates a Dockerfile is created automatically every Monday at 09:00 JST.
   - Dependabot updates the tag and the digest of the base images ([.github/dependabot.yml](./.github/dependabot.yml)).
   - The `update-ubi-packages` workflow updates the RPM packages pinned in `jre-ubi/*/Dockerfile`, because Dependabot cannot detect them ([.github/workflows/update-ubi-packages.yaml](./.github/workflows/update-ubi-packages.yaml)).
2. The CI builds the images in the pull request and comments the images that will be released ([.github/workflows/jre-ci.yaml](./.github/workflows/jre-ci.yaml)).
3. A maintainer merges the pull request.
4. The release workflow of each changed directory builds the image and pushes it to `ghcr.io` (`.github/workflows/jre*-release.yaml`, which call [jre-release-reusable.yaml](./.github/workflows/jre-release-reusable.yaml)).
5. The maintainer checks that the release workflow has succeeded. Nothing notifies a failed release except the notification of GitHub Actions itself.

Dependabot also creates a pull request that updates the actions used in the workflows. Merging it does not release an image.

Note the following about the pull requests.

- No reviewer is assigned to them automatically. A maintainer must look for them.
- The `update-ubi-packages` workflow creates one pull request for each Java version, and it updates all the packages pinned in the Dockerfile, including `shadow-utils`. If the pull request is still open in the next run, the workflow updates it instead of creating another one.
- The author of the pull requests of the `update-ubi-packages` workflow is the owner of `GH_PR_PAT`, so that account cannot approve them.
- To look for the updates without waiting for Monday, run the `update-ubi-packages` workflow manually on the `main` branch, or run the check of Dependabot manually from the dependency graph of the repository. If the `update-ubi-packages` workflow is run on another branch, it creates a pull request to that branch.

### What is not updated automatically

Update the following manually.

- **The OS release of the `eclipse-temurin` image.** Dependabot keeps the suffix of the tag (for example, `-jre-resolute`), so it does not move to the image of another Ubuntu release.
- **The Java major version.** `.github/dependabot.yml` ignores the major version updates of `eclipse-temurin`, and the name of the OpenJDK package includes the major version. See [How to add an image of a new Java version](#how-to-add-an-image-of-a-new-java-version).
- **The major version of UBI.** `ubi10/ubi-minimal` is an image name, not a tag.
- **The packages that are not pinned as `<name>-[<epoch>:]<version>-<release>`.** `ci/update_ubi_packages.sh` skips them.
  - The script judges the format only from the name, so it cannot skip an unpinned package whose name itself matches the format. For example, it reads `java-21-openjdk` as the package `java` with the version `21` and the release `openjdk`, and fails with "Failed to find java".
- **The reusable workflow of the vulnerability check.** `jre-vuln-check.yaml` calls `scalar-labs/actions/.github/workflows/vuln-check-reusable.yaml@main`. It always uses the head of the `main` branch of that repository, so a change there takes effect without a change in this repository.

### What the CI checks

`jre-ci.yaml` runs in the pull requests that change a JRE image directory, `ci/get_jre_version.sh`, or `jre-ci.yaml` itself.

- It checks all four images in every run, not only the changed one. A pull request fails if another image cannot be built.
- It checks that the JRE version can be taken from each Dockerfile and that each image can be built for `linux/amd64` and `linux/arm64`. It does not run the images, so it does not check that the JRE works.
- It comments the images and the tags that will be released, and updates the same comment in the following runs. It does not comment in the pull requests from forks.
- It does not run for a change only in the release workflows, `update-ubi-packages.yaml`, or `ci/update_ubi_packages.sh`. Those changes are used for the first time after the merge.

### What a maintainer does every week

1. Check the open pull requests of Dependabot and the `update-ubi-packages` workflow.
2. In each pull request, check that the CI has succeeded and that the comment of the CI shows the expected image and tag.
3. Merge the pull requests. If two pull requests change the same directory, wait until the release of the first one finishes before merging the second one. Otherwise, the first release may fail with "differs from the head of the main branch", which is harmless because the second release includes both changes.
4. Check that the release workflows have succeeded.
5. Check the result of the `jre-vuln-check` workflow. It posts a message to Slack only when a scan fails, so also check that the run of the workflow has succeeded. See [Vulnerability check](#vulnerability-check).

Note the following about the release.

- A release workflow runs only when a file under its directory (for example, `jre/21/**`) changes on the `main` branch. A change only in `ci/` or in the workflows does not release an image.
- To release an image without changing the Dockerfile, run the release workflow manually (`workflow_dispatch`) on the `main` branch. A manual run on another branch does not release anything.
- The OS packages are updated (`apt-get upgrade` or `microdnf update`) only when an image is built for a release. If no pull request changes a directory for a long time, the released image keeps the old OS packages. Run the release workflow manually to release an image with the latest OS packages.
- The JRE version in the tag changes only when the tag of the `eclipse-temurin` image or the pinned OpenJDK package changes. The other releases have the same JRE version and a newer build time.

### How to withdraw a released image

A released tag cannot be replaced. Release a newer image instead.

1. Revert the pull request that caused the problem and merge the revert. The release workflow releases a new image with a newer build time.
2. Dependabot proposes the new image to the repositories that use the image. The repositories that have already updated to the bad image keep using it until they merge that update.

This works only when the revert does not lower the JRE version in the tag. If it does (for example, the revert of an update from `21.0.12_7` to `21.0.13_9`), the new tag is older for Dependabot, so the repositories that use the image must change the `FROM` instruction manually.

## Vulnerability check

The `jre-vuln-check` workflow scans the images every Monday at 01:00 JST ([.github/workflows/jre-vuln-check.yaml](./.github/workflows/jre-vuln-check.yaml)).

- It posts a message to Slack only when the scan of an image fails, that is, when the scan finds a `CRITICAL` or `HIGH` vulnerability that has a fix. It posts nothing when the scan finds no such vulnerability.

- It scans the images that it builds from the head of the `main` branch, not the released images. When a base image or a pinned package is updated, a pull request is created, and merging it releases a new image, so the released image is expected to be close to the image built from the head of the `main` branch.
- It cannot find a vulnerability that only the released image has. The build updates the OS packages (`apt-get upgrade` or `microdnf update`), so if a fix is published only in the package repositories while the base image and the pinned packages stay the same, the image built for the scan has the fix and the scan succeeds, but the released image does not have the fix until the next release. No pull request is created in this case. To release an image with the latest OS packages, run the release workflow manually.
- This relies on merging the update pull requests without delay. See [Assumptions about the operation](#assumptions-about-the-operation).
- It scans none of the images if one of the builds fails. In that case, it posts nothing to Slack, and only the run of the workflow fails. No message in Slack does not mean that the images have no vulnerability unless the run has succeeded.

When a vulnerability is reported, do the following.

1. Merge the open pull requests of Dependabot and the `update-ubi-packages` workflow if any. If there is none, look for the updates manually. See [How the images are updated and released](#how-the-images-are-updated-and-released).
2. If the vulnerability is still reported, the base image or the package repositories do not have the fix yet. Wait for the fix, and repeat these steps.

## Assumptions about the operation

The workflows rely on the following. Review the workflows before changing any of them.

- **A maintainer merges the pull requests, including the ones of Dependabot.** If Dependabot itself merges a pull request, the release workflow gets the Dependabot secrets instead of the Actions secrets, so `CR_PAT` is empty and the release fails.
- **The update pull requests are merged without delay.** The released images are replaced only by a new release, and the vulnerability check does not scan the released images. In addition, the repositories of the UBI base image remove the old versions of the packages, so the UBI based images cannot be built once a pinned version is removed. See [Troubleshooting](#troubleshooting).
- **Nobody pushes commits to the branches of the `update-ubi-packages` workflow** (`update-ubi-packages/<base branch>/jre-ubi-<version>`). The workflow recreates the branch and force-pushes it, so such commits are discarded.
- **A closed pull request of the `update-ubi-packages` workflow is created again** in the next run if the update is still available.

## Rules for editing the Dockerfiles

The scripts in `ci/` parse the Dockerfiles, so keep the following formats.

- `jre/*/Dockerfile`
  - Keep the full JRE version in the tag of the base image, for example `eclipse-temurin:21.0.13_9-jre-resolute@sha256:...`. `ci/get_jre_version.sh` takes the JRE version from it. A tag without the build number (for example, `21-jre-resolute`) is not accepted.
  - Write the image name right after `FROM`. An option such as `FROM --platform=...` is not accepted.
  - Use only one `eclipse-temurin` image in a Dockerfile.
- `jre-ubi/*/Dockerfile`
  - Pin the packages as `<name>-[<epoch>:]<version>-<release>`, for example `java-21-openjdk-headless-1:21.0.13.0.9-1.2.el10`. `ci/get_jre_version.sh` takes the JRE version from the OpenJDK package.
  - Pin only one OpenJDK package (`java-<version>-openjdk` or `java-<version>-openjdk-headless`).
  - Put all the packages on the same line as `microdnf install`. `ci/update_ubi_packages.sh` does not read the packages on continuation lines.
  - Keep the UBI image in the first `FROM` instruction. `ci/update_ubi_packages.sh` looks for the latest packages in the repositories of the image in the first `FROM` instruction.
  - Do not remove `shadow-utils`. The products that use the image run the `useradd` command, which this package provides.
- Keep the `ARG` instructions (`IMAGE_NAME`, `IMAGE_VERSION`, and `IMAGE_RELEASE`) and the labels that use them. The release workflow passes the values as build arguments.
- The directory name must be the Java major version. `ci/get_jre_version.sh` fails if the JRE version in the Dockerfile is a different major version.

The CI runs `ci/get_jre_version.sh` in pull requests, so a Dockerfile from which the JRE version cannot be taken is found before the merge. Nothing checks the rules for `ci/update_ubi_packages.sh` (the continuation lines and the first `FROM` instruction).

`ci/update_ubi_packages.sh` has the following limitations.

- It compares the versions with `sort -V`, which is not exactly the same as the version comparison of RPM, and it does not compare the epoch. Check the versions in the pull request.
- It looks for the packages on the `linux/amd64` runner only. The CI of the pull request checks that the same versions can be installed on `linux/arm64`.

## How to add an image of a new Java version

Update all of the following. Nothing detects a missing one.

1. Add `jre/<version>/Dockerfile` and `jre-ubi/<version>/Dockerfile`.
2. Add the release workflows `.github/workflows/jre<version>-release.yaml` and `.github/workflows/jre<version>-ubi-release.yaml`.
3. In `.github/workflows/jre-ci.yaml`, add the directories to `on.pull_request.paths`, to the matrix of the `build` job, and to the `images` list of the `comment` job.
4. In `.github/workflows/jre-vuln-check.yaml`, add the images to `images` and to `docker-build-command`.
5. In `.github/workflows/update-ubi-packages.yaml`, add the Java version to the matrix.
6. In `.github/dependabot.yml`, add the directories to `directories`.

The image name must be the same in the release workflow, `jre-ci.yaml`, and `jre-vuln-check.yaml`.

After the first release, check the visibility and the access settings of the new package in `ghcr.io`, so that the products and their Dependabot can pull the image.

To remove the image of a Java version, remove the same items. Do not delete the released images from `ghcr.io` while a product uses them.

## How to check the changes locally

```console
# Build an image.
docker build ./jre/21

# Show the JRE version that is used in the image tag.
bash ci/get_jre_version.sh jre/21

# Update the packages pinned in a UBI based Dockerfile. This changes the Dockerfile in place and
# runs the base image with `docker run` to look for the latest versions.
bash ci/update_ubi_packages.sh jre-ubi/21/Dockerfile
```

The workflows cannot be run locally. `jre-ci.yaml` runs in pull requests, and the release workflows run only on the `main` branch.

## Secrets

| Secret | Used by | Purpose |
| --- | --- | --- |
| `CR_PAT` | `jre-release-reusable.yaml` | Log in to `ghcr.io`. |
| `GH_PR_PAT` | `update-ubi-packages.yaml` | Push the branch and create the pull request. A PAT is used instead of `GITHUB_TOKEN` so that the CI runs in the pull request. |
| `SLACK_SECURITY_WEBHOOK_URL` | `jre-vuln-check.yaml` | Post a message to Slack when the vulnerability check of an image fails. |

- `CR_PAT` and `GH_PR_PAT` are secrets of the organization, not of this repository.
- `CR_PAT` needs the permission to push the packages of `ghcr.io/scalar-labs`. `GH_PR_PAT` needs the permission to push branches and to create pull requests in this repository.
- If a PAT expires or loses the permission, the workflows that use it fail. See [Troubleshooting](#troubleshooting).
- `jre-ci.yaml` uses no secrets, so it also works in the pull requests of Dependabot.

## Troubleshooting

- **The build of a UBI based image fails because a pinned package is not found.**
  The repositories of the base image remove the old versions of the packages, so the pinned version is no longer available. Run the `update-ubi-packages` workflow manually, or merge the pull request that it has already created. Until then, the following also fail.
  - The CI of the other pull requests that change `jre-ubi/`, including the ones of Dependabot. Merge the pull request of the `update-ubi-packages` workflow first, and then update the other pull requests.
  - The `jre-vuln-check` workflow. It scans none of the images if one of the builds fails, and it posts nothing to Slack.

  If the `update-ubi-packages` workflow reports that the package is up to date although the build fails, `sort -V` orders the available version before the pinned one. `ci/update_ubi_packages.sh` never lowers a version, so it creates no pull request. Change the pinned version in the Dockerfile manually to the available one that the log of the workflow shows.
- **The release fails with "differs from the head of the main branch".**
  The run checked out a commit that is older than the head of the `main` branch. This happens in a re-run of an old run, or when another commit to the same directory is merged before the run starts. If no later run has released the directory, run the release workflow manually on the `main` branch.
- **The release fails in the login to `ghcr.io` or in the push of the image.**
  Check that `CR_PAT` has not expired and that it can push the package. If the run was triggered by a merge that Dependabot itself did, `CR_PAT` is empty. See [Assumptions about the operation](#assumptions-about-the-operation). After fixing the cause, run the release workflow manually on the `main` branch.
- **The release fails with "Failed to get the JRE version" or "does not match the directory name".**
  The Dockerfile does not follow [Rules for editing the Dockerfiles](#rules-for-editing-the-dockerfiles). The CI reports the same error in the pull request, so this happens only when the pull request was merged with a failed CI.
- **The `update-ubi-packages` workflow fails in the push of the branch or in the creation of the pull request.**
  Check that `GH_PR_PAT` has not expired and that it has the permission for this repository.
- **The CI does not run in a pull request of the `update-ubi-packages` workflow.**
  The pull request was created with a token that does not trigger workflows. Check that the workflow uses `GH_PR_PAT` for both the checkout and `GH_TOKEN`. Closing and reopening the pull request runs the CI.
- **The CI fails in the `comment` job in a pull request of Dependabot.**
  The job needs the `pull-requests: write` permission of `GITHUB_TOKEN`. Check the `permissions` of the job and the default permissions of `GITHUB_TOKEN` in the settings of the repository.

## What to check after the operation starts

**The following items cannot be judged by code review alone. They must be checked in the actual environment.**

The workflows and the configurations have been checked only by reading the code, and they have not been run. The items below depend on things outside the code of this repository, such as the behavior of the Dependabot service, the permissions of the secrets, the settings of the repository and the packages, and the contents of the package repositories of Red Hat. A reviewer cannot confirm them from the pull request.

Check them in the first runs, and remove each item after it is confirmed. Each section says why the items cannot be judged by code review.

### Release

Why code review is not enough: The result depends on the permission of `CR_PAT`, the settings of the packages in `ghcr.io`, and which secrets GitHub passes to the run. The release workflows run only on the `main` branch, so they cannot be run in a pull request.

- [ ] The release workflow of each of the four images succeeds after a merge into the `main` branch, and `CR_PAT` can push the new packages (`jre21`, `jre25`, `jre21-ubi`, and `jre25-ubi`).
- [ ] The tag is `<JRE version>.<YYYYMMDDhhmm>`, and the image has the manifests for both `linux/amd64` and `linux/arm64`.
- [ ] The labels `name`, `version`, and `release` of the released image have the expected values.
- [ ] The summary of the run shows the `FROM` instruction with the digest.
- [ ] The visibility and the access settings of the new packages in `ghcr.io` allow the products to pull the images.
- [ ] The release workflow gets `CR_PAT` when a maintainer merges a pull request of Dependabot.

### Dependabot in this repository

Why code review is not enough: Dependabot is a service of GitHub. Which experiments are enabled in it is not visible, and its behavior was only read from the source code of dependabot-core. Dependabot reads `.github/dependabot.yml` only from the default branch, so it does not run before the merge.

- [ ] Dependabot creates the pull requests that update the tag and the digest of `eclipse-temurin` in `jre/21` and `jre/25`.
- [ ] Dependabot does not propose a major version update of `eclipse-temurin` (for example, from 21 to 25).
- [ ] Dependabot creates the pull requests that update `ubi10/ubi-minimal` in `jre-ubi/21` and `jre-ubi/25`, and the new tag has the same format as the current one (a number such as `1793835006`).
- [ ] Dependabot creates a pull request when only the digest of `eclipse-temurin` changes and the tag stays the same. The policy of not scanning the released images relies on this. See [Vulnerability check](#vulnerability-check).
- [ ] The pull request for the actions updates both the commit hash and the version comment (for example, `# v7.0.1`), and it includes all the actions in one pull request.

### CI

Why code review is not enough: The permissions of `GITHUB_TOKEN` in the pull requests of Dependabot depend on the settings of the repository and on how GitHub handles those pull requests. The comment is created with the API of GitHub, which was not called in the local check.

- [ ] `jre-ci.yaml` runs in the pull requests of Dependabot, and the `build` job succeeds for the four images.
- [ ] The `comment` job can create the comment in a pull request of Dependabot. It needs the `pull-requests: write` permission of `GITHUB_TOKEN`.
- [ ] The `comment` job updates the existing comment in the second run instead of adding another one.
- [ ] The image and the tag in the comment match the released ones except for the build time.

### `update-ubi-packages` workflow

Why code review is not enough: The result depends on the permission of `GH_PR_PAT`, on the actual output of `microdnf repoquery` in the UBI image, and on the versions in the package repositories of Red Hat. The script was checked only for its syntax, and it was not run with the base image.

- [ ] `GH_PR_PAT` can push the branch and create the pull request in this repository.
- [ ] `ci/update_ubi_packages.sh` finds the latest versions. It assumes that `microdnf repoquery --available` prints each package as `<name>-[<epoch>:]<version>-<release>.<arch>`.
- [ ] The workflow creates no pull request when all the packages are up to date. In particular, it does not create a pull request that only adds or removes the epoch, or that lowers a version.
- [ ] `jre-ci.yaml` runs in the pull request that the workflow creates.
- [ ] The workflow does not create another pull request, and does not push again, when the open pull request already proposes the same update.

### Vulnerability check

Why code review is not enough: The workflow calls a reusable workflow of another repository (`scalar-labs/actions`), and it runs only on a schedule or manually. Whether its inputs match what the reusable workflow expects is known only by running it.

- [ ] The `jre-vuln-check` workflow builds and scans the four images, and posts a message to Slack when the scan of an image fails.

### Repositories that use the images

Why code review is not enough: These items are about Dependabot of other repositories, and they can be checked only after an image is released and a repository uses it. The comparison of the tags was confirmed by reading the source code of dependabot-core and RubyGems, not by running Dependabot against the released tags.

- [ ] Dependabot of a repository that uses an image can read the tags of the image in `ghcr.io`. If the package is private, the repository needs the configuration of the registry in its `dependabot.yml`.
- [ ] Dependabot proposes the update to a newer build time with the same JRE version (for example, from `21.0.13_9.202611120130` to `21.0.13_9.202611190130`), and it updates the tag and the digest together.
- [ ] Dependabot proposes the update to a newer JRE version (for example, from `21.0.13_9.<build time>` to `21.0.14_7.<build time>`).

## Other images

Only the four JRE images in [JRE images](#jre-images) are maintained. The following images are out of the scope of the regular update and release.

| Directory | Image |
| --- | --- |
| `jre/8` | `ghcr.io/scalar-labs/jre8` |
| `jdk/8` | `ghcr.io/scalar-labs/jdk8` |
| `jdk-postgres/8-15` | `ghcr.io/scalar-labs/jdk8-postgres15` |
| `oracle-jdk-installer-for-windows` | See [oracle-jdk-installer-for-windows/README.md](./oracle-jdk-installer-for-windows/README.md). |

- Dependabot does not update their base images, because their directories are not in `.github/dependabot.yml`.
- No workflow releases them automatically. The workflows `jre8-release.yml` and `jdk8-release.yml` run only when a Git tag (`jre8-<version>` or `jdk8-<version>`) is pushed.
- The pull request of Dependabot that updates the actions also changes their workflows, because the `github-actions` ecosystem covers all the workflows in `.github/workflows`.
