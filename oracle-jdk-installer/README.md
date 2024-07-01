# Docker images containing installer for Oracle JDK 8 and 11 on Linux and Windows

This folder contains Dockerfiles to build images that contain Oracle JDK 8 or 11 installer for Linux and Windows.
Their purpose is to help install Oracle JDK 8 and 11 on the GitHub action runner. 
The runner will create the image containing the JDK installer and copy it locally for installation after which the started image is discarded.
For example, an Ubuntu runner will do the following steps to retrieve JDK 8 installer:

```bash
container_id=$(docker create "ghcr.io/scalar-labs/oracle/jdk:8")  
docker cp "$container_id:oracle-jdk-8.tar.gz" "./oracle-jdk-8.tar.gz"  
docker rm "$container_id"
//Continue with the JDK installation
```

The capability of the base image used, `alpine` for Linux, and `mcr.microsoft.com/oss/kubernetes/windows-host-process-containers-base-image` is irrelevant. 
They were selected solely because their memory footprint is very light: about 5MB for alpine and 7KB for the windows image.

## How to build the images 
### Download the JDK installer

Download the installer from [Oracle website](https://www.oracle.com/java/technologies/downloads/archive/#JavaSE). An Oracle account (registration is free) is needed.
- For Linux, download the `Linux x64 Compressed Archive` for Oracle JDK 8 and 11.
- For Windows, download the `Windows x64 Installer` for Oracle JDK 8 and 11.

Then put the downloaded files in the corresponding directories with the Dockerfile

### Build the Docker images
#### For Linux

Run the following commands to build the Linux images

##### For JDK 8

```bash
 docker build -t ghcr.io/scalar-labs/oracle/jdk:8-linux -t ghcr.io/scalar-labs/oracle/jdk:8u401-linux ./linux/8
 ```

##### For JDK 11

```bash
 docker build -t ghcr.io/scalar-labs/oracle/jdk:11-linux -t ghcr.io/scalar-labs/oracle/jdk:11.0.22-linux ../linux/11
```

#### For Windows

These builds steps are directly taken from base image `mcr.microsoft.com/oss/kubernetes/windows-host-process-containers-base-image:v1.0.0` [GitHub repository](https://github.com/microsoft/windows-host-process-containers-base-image?tab=readme-ov-file#build-with-buildkit).

To be able to build a Windows image on a Linux machine, we need to create a specific build environment.

```bash
docker buildx create --name img-builder --use --platform windows/amd64
```

Since the image requires a Windows architecture, it cannot be exported locally after being build,
we need to push it to the registry right away.

The following commands will build then push the Windows image to the Scalar GitHub registry.

##### For JDK 8

```bash
docker buildx build --platform windows/amd64 --output=type=registry -t ghcr.io/scalar-labs/oracle/jdk:8-windows -t ghcr.io/scalar-labs/oracle/jdk:8u401-windows ./windows/8
```

##### For JDK 11

```bash
docker buildx build --platform windows/amd64 --output=type=registry -t ghcr.io/scalar-labs/oracle/jdk:11-windows -t ghcr.io/scalar-labs/oracle/jdk:11.0.22-windows ./windows/11
```



