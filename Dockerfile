# syntax=docker/dockerfile:1
FROM alpine:latest

ENV S6_BEHAVIOUR_IF_STAGE2_FAILS="2" \
    SOCKLOG_TIMESTAMP_FORMAT="" \
    TZ="UTC" \
    FTP_UID="1000" \
    FTP_GID="1000" \
    FTP_USR="proftpd" \
    FTP_GRP="nogroup" \
    FTP_SSL="/pure-ftpd/ssl" \
    FTP_DIR="/pure-ftpd/ftp" \
    FTP_PWD="/pure-ftpd/data/pureftpd.passwd" \
    FTP_PDB="/pure-ftpd/data/pureftpd.pdb"

RUN apk --update --no-cache upgrade
RUN apk --update --no-cache add curl ca-certificates pure-ftpd s6-overlay tzdata libretls libsodium
RUN apk add --no-cache --virtual .tool-deps coreutils autoconf g++ libtool make
RUN apk add --no-cache --virtual .build-deps libretls-dev libsodium-dev
RUN curl -sSfL -o /tmp/pure-ftpd.tar.gz https://download.pureftpd.org/pub/pure-ftpd/releases/pure-ftpd-1.0.52.tar.gz
RUN tar -xzf /tmp/pure-ftpd.tar.gz -C /tmp/
RUN cd /tmp/pure-ftpd-1.0.52; ./configure \
        --prefix=/usr \
        --with-altlog \
        --with-ftpwho \
        --with-puredb \
        --with-peruserlimits \
        --with-rfc2640 \
        --without-capabilities \
        --without-humor \
        --without-inetd \
        --without-usernames \
        --without-pam \
RUN cd /tmp/pure-ftpd-1.0.52; make
RUN cd /tmp/pure-ftpd-1.0.52; make install

COPY rootfs /
RUN chmod +x /etc/cont-init.d/*

EXPOSE 21000/tcp 21001-22011/tcp
WORKDIR "/pure-ftpd/data"
VOLUME [ "/pure-ftpd/data" ]

ENTRYPOINT [ "/init" ]
