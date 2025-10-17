# syntax=docker/dockerfile:1
FROM alpine:latest

ENV S6_BEHAVIOUR_IF_STAGE2_FAILS="2" \
    SOCKLOG_TIMESTAMP_FORMAT="" \
    TZ="UTC" \
    FTP_UID="1000" \
    FTP_GID="1000" \
    FTP_USR=proftpd \
    FTP_GRP=nogroup \
    FTP_SSL="/pure-ftpd/ssl" \
    FTP_DIR="/pure-ftpd/ftp" \
    FTP_PWD="/pure-ftpd/data/pureftpd.passwd" \
    FTP_PDB="/pure-ftpd/data/pureftpd.pdb"

RUN apk --update --no-cache upgrade && \
    apk --update --no-cache add \
    pure-ftpd \
    s6-overlay \
    tzdata; \
    addgroup -g "${FTP_GID}" "${FTP_GRP}"; \
    adduser --disabled-password -M -u "${FTP_UID}" -g "${FTP_GRP}" "${FTP_USR}"; \
    rm -rf /etc/periodic; \
    rm -f /etc/socklog.rules/*; \
    rm -rf /tmp/*

COPY rootfs /

EXPOSE 21000/tcp 21001-22011/tcp
WORKDIR "/pure-ftpd/data"
VOLUME [ "/pure-ftpd/data" ]

ENTRYPOINT [ "/init" ]
