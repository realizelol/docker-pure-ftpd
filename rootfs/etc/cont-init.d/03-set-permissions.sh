#!/usr/bin/with-contenv sh
# shellcheck shell=sh
# shellcheck enable=require-variable-braces

# set permissions
chown -R "${FTP_UID}:${FTP_GID}" /pure-ftpd
