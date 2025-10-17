#!/usr/bin/with-contenv sh
# shellcheck shell=sh
# shellcheck enable=require-variable-braces

# Fix access rights to stdout and stderr
chown "${FTP_UID}:${FTP_GID}" /proc/self/fd/1 /proc/self/fd/2 || true
