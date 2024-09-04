# Docker images containing installer for Oracle JDK 8 and 11 on Windows

This folder contains Dockerfiles to build images that contain Oracle JDK 8 or 11 installer for Windows.
We need such image because no [official Oracle JDK image](https://container-registry.oracle.com/ords/ocr/ba/java/jdk) for Windows architecture exists to this date.
These image purpose is to help install Oracle JDK 8 and 11 on the GitHub Windows action runner.
The runner will create the image containing the JDK installer and copy it locally for installation after which the started image is discarded.
For example, the runner will do the following steps to retrieve JDK 8 installer:

```bash
$container_id=$(docker create "ghcr.io/scalar-labs/oracle/jdk:8-windows")
docker cp "${container_id}:oracle-jdk.exe" .
docker rm "$container_id"
//Continue with the JDK installation
```

The capability of the `mcr.microsoft.com/oss/kubernetes/windows-host-process-containers-base-image` base image is irrelevant since the container is never run. 
It was selected solely because its memory footprint is very light (7KB).

## How to build the images 
### Download the JDK installer

Download the `Windows x64 Installer` installer from [Oracle website](https://www.oracle.com/java/technologies/downloads/archive/#JavaSE) for JDK 8 and 11. An Oracle account (registration is free) is needed.

Then put the downloaded files in the corresponding directories with the Dockerfile

### Build the Docker images

These builds steps are directly taken from the base image `mcr.microsoft.com/oss/kubernetes/windows-host-process-containers-base-image` [GitHub repository](https://github.com/microsoft/windows-host-process-containers-base-image?tab=readme-ov-file#build-with-buildkit).

To be able to build a Windows image on a Linux machine, we need to create a specific build environment.

```bash
docker buildx create --name img-builder --use --platform windows/amd64
```

Since the image requires a Windows architecture, it cannot be exported locally after being build,
we need to push it to the registry right away.

The following commands will build then push the Windows image to the Scalar GitHub registry.

#### For JDK 8

```bash
docker buildx build --platform windows/amd64 --output=type=registry -t ghcr.io/scalar-labs/oracle/jdk:8-windows -t ghcr.io/scalar-labs/oracle/jdk:8u401-windows ./8
```

#### For JDK 11

```bash
docker buildx build --platform windows/amd64 --output=type=registry -t ghcr.io/scalar-labs/oracle/jdk:11-windows -t ghcr.io/scalar-labs/oracle/jdk:11.0.22-windows ./11
```
