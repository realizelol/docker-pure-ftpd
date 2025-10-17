#!/usr/bin/with-contenv sh
# shellcheck shell=sh
# shellcheck enable=require-variable-braces

# Delete default cronjobs in periodic folder
rm -rf /etc/periodic*
