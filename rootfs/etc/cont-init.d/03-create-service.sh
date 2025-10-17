#!/usr/bin/with-contenv sh
# shellcheck shell=sh
# shellcheck enable=require-variable-braces

mkdir -p /etc/services.d/pure-ftpd

cat > /etc/services.d/pure-ftpd/run <<EOF
#!/usr/bin/with-contenv sh
pure-ftpd${PUREFTPD_FLAGS:-$(cat /var/run/s6/container_environment/PUREFTPD_FLAGS)} \
  2>&1 | s6-socklog
EOF
chmod +x /etc/services.d/pure-ftpd/run

mkdir -p /var/run/s6/services
cat > /etc/services.d/pure-ftpd/finish <<EOF
#!/usr/bin/with-contenv sh
echo >&2 "pure-ftpd exited. code=${?}"
exec s6-svscanctl -t /var/run/s6/services
EOF
chmod +x /etc/services.d/pure-ftpd/finish
