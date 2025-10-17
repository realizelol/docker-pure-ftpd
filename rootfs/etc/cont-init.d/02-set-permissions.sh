#!/usr/bin/with-contenv sh
# shellcheck shell=sh
# shellcheck enable=require-variable-braces

# set permissions
chown -R "${PUID}:${PGID}" /pure-ftpd
