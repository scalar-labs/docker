FROM openjdk:8u322-jre-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    liblz4-1=1.9.3-2 \
    libgcrypt20=1.8.7-6 \
    libgnutls30=3.7.1-5 \
    libhogweed6=3.7.3-1 \
    libssl1.1=1.1.1n-0+deb11u3 \
    openssl=1.1.1n-0+deb11u3 \
    libgmp10=2:6.2.1+dfsg-1+deb11u1 \
    zlib1g=1:1.2.11.dfsg-2+deb11u1 \
    gzip=1.10-4+deb11u1 \
    liblzma5=5.2.5-2.1~deb11u1 \
    dpkg=1.20.10 \
    && rm -rf /var/lib/apt/lists/*
