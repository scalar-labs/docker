FROM openjdk:8u322-jre-slim

RUN apt-get update && \
    apt-get install -y --no-install-recommends liblz4-1=1.8.3-1+deb10u1 libgcrypt20=1.8.4-5+deb10u1 libgnutls30=3.6.7-4+deb10u7 libhogweed4=3.4.1-1+deb10u1 libssl1.1=1.1.1d-0+deb10u8 openssl=1.1.1d-0+deb10u8 libgmp10=2:6.1.2+dfsg-4+deb10u1 && \
    rm -rf /var/lib/apt/lists/*
