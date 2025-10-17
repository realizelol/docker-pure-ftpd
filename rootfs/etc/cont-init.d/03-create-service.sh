#!/usr/bin/with-contenv sh
# shellcheck shell=sh
# shellcheck enable=require-variable-braces

if [ -z "${PUREFTPD_FLAGS}" ]; then
  PUREFTPD_FLAGS=$(cat /var/run/s6/container_environment/PUREFTPD_FLAGS)
fi

mkdir -p /etc/services.d/pure-ftpd

cat > /etc/services.d/pure-ftpd/run <<EOF
#!/usr/bin/execlineb -P
with-contenv
pure-ftpd ${PUREFTPD_FLAGS}
EOF
chmod +x /etc/services.d/pure-ftpd/run

mkdir -p /var/run/s6/services
cat > /etc/services.d/pure-ftpd/finish <<EOF
#!/usr/bin/with-contenv sh
echo >&2 "pure-ftpd exited. code=${1}"
exec s6-svscanctl -t /var/run/s6/services
EOF
chmod +x /etc/services.d/pure-ftpd/finish
