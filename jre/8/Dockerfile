FROM openjdk:8u322-jre-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    liblz4-1=1.9.3-2 \
    libgcrypt20=1.8.7-6 \
    libgnutls30=3.7.1-5+deb11u3 \
    libhogweed6=3.7.3-1 \
    libssl1.1=1.1.1n-0+deb11u5 \
    openssl=1.1.1n-0+deb11u5 \
    libgmp10=2:6.2.1+dfsg-1+deb11u1 \
    zlib1g=1:1.2.11.dfsg-2+deb11u2 \
    gzip=1.10-4+deb11u1 \
    liblzma5=5.2.5-2.1~deb11u1 \
    dpkg=1.20.10 \
    libtirpc-common=1.3.1-1+deb11u1 \
    libtirpc3=1.3.1-1+deb11u1 \
    libc-bin=2.31-13+deb11u9 \
    libc6=2.31-13+deb11u9 \
    libpcre2-8-0=10.36-2+deb11u1 \
    libtasn1-6=4.16.0-2+deb11u1 \
    libdb5.3=5.3.28+dfsg1-0.8 \
    libgssapi-krb5-2=1.18.3-6+deb11u3 \
    libk5crypto3=1.18.3-6+deb11u3 \
    libkrb5-3=1.18.3-6+deb11u3 \
    libkrb5support0=1.18.3-6+deb11u3 \
    libtinfo6=6.2+20201114-2+deb11u2 \
    ncurses-base=6.2+20201114-2+deb11u2 \
    ncurses-bin=6.2+20201114-2+deb11u2 \
    perl-base=5.32.1-4+deb11u3 \
    bsdutils=1:2.36.1-8+deb11u2 \
    libblkid1=2.36.1-8+deb11u2 \
    libmount1=2.36.1-8+deb11u2 \
    libsmartcols1=2.36.1-8+deb11u2 \
    libuuid1=2.36.1-8+deb11u2 \
    mount=2.36.1-8+deb11u2 \
    util-linux=2.36.1-8+deb11u2 \
    && rm -rf /var/lib/apt/lists/*
