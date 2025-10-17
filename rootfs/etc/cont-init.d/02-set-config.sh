#!/usr/bin/with-contenv sh
# shellcheck shell=sh
# shellcheck enable=require-variable-braces

TZ=${TZ:-UTC}
CONTAINER_IP="$(ip a show "$(netstat -r | awk '/^default/{print$8}')" | sed -nr 's%.*inet ([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3})/[0-9]{1,2} .*%\1%p')"
SECURE_MODE=${SECURE_MODE:-true}
ACTIVE_PORT=${ACTIVE_PORT:-21000}
PASSIVE_IP=${PASSIVE_IP:-${CONTAINER_IP}}
PASSIVE_PORT_RANGE=${PASSIVE_PORT_RANGE:-21001:21011}
PFTPD_FLAGS="/pure-ftpd/data/pureftpd.flags"
PFTPD_PUREDB="/pure-ftpd/data/pureftpd.pdb"
PFTPD_PASSWD="/pure-ftpd/data/pureftpd.passwd"
PFTPD_PEM="/pure-ftpd/data/pureftpd.pem"
PFTPD_DHPARAMS="/pure-ftpd/data/pureftpd-dhparams.pem"

# pre-config

[ -d /pure-ftpd/data ] || mkdir -p /pure-ftpd/data
[ -d /pure-ftpd/ftp ] || mkdir -p /pure-ftpd/ftp
[ -d /pure-ftpd/ssl ] || mkdir -p /pure-ftpd/ssl

# Timezone
echo "Setting timezone to ${TZ}..."
ln -snf "/usr/share/zoneinfo/${TZ}" /etc/localtime
echo "${TZ}" > /etc/timezone

# create pure-ftpd database
touch "${PFTPD_PUREDB}" "${PFTPD_PASSWD}"
pure-pw mkdb "${PFTPD_PUREDB}" -f "${PFTPD_PASSWD}"

# Check TLS cert
if [ -f "${PFTPD_PEM}" ]; then
  chmod 600 "${PFTPD_PEM}"
fi
if [ -f "${PFTPD_DHPARAMS}" ]; then
  chmod 600 "${PFTPD_DHPARAMS}"
  ln -sf "${PFTPD_DHPARAMS}" "/${FTP_SSL}/pure-ftpd-dhparams.pem"
fi

# Create FLAGS

unset ADD_FLAGS
if [ -f "${PFTPD_FLAGS}" ]; then
  while read -r FLAG; do
    test -n "${FLAG}" && ADD_FLAGS="${ADD_FLAGS} ${FLAG}"
  done < "${PFTPD_FLAGS}"
  FLAGS="${FLAGS}${ADD_FLAGS}"
fi

FLAGS="${FLAGS} --bind 0.0.0.0,${ACTIVE_PORT}"
FLAGS="${FLAGS} --ipv4only"
FLAGS="${FLAGS} --passiveportrange ${PASSIVE_PORT_RANGE}"
FLAGS="${FLAGS} --noanonymous"
FLAGS="${FLAGS} --createhomedir"
FLAGS="${FLAGS} --nochmod"
FLAGS="${FLAGS} --syslogfacility ftp"
FLAGS="${FLAGS} --login puredb:${PFTPD_PUREDB}"

if [ -n "${PASSIVE_IP}" ]; then
  FLAGS="${FLAGS} --forcepassiveip ${PASSIVE_IP}"
fi

# Secure mode
unset SECURE_FLAGS
if [ "${SECURE_MODE}" = "true" ]; then
  SECURE_FLAGS="${SECURE_FLAGS} --maxclientsnumber 1"
  SECURE_FLAGS="${SECURE_FLAGS} --maxclientsperip 10"
  SECURE_FLAGS="${SECURE_FLAGS} --antiwarez"
  SECURE_FLAGS="${SECURE_FLAGS} --customerproof"
  SECURE_FLAGS="${SECURE_FLAGS} --dontresolve"
  SECURE_FLAGS="${SECURE_FLAGS} --norename"
  SECURE_FLAGS="${SECURE_FLAGS} --prohibitdotfilesread"
  SECURE_FLAGS="${SECURE_FLAGS} --prohibitdotfileswrite"
  FLAGS="${FLAGS}${SECURE_FLAGS}"
fi

echo "Flags"
echo "  Secure:${SECURE_FLAGS}"
echo "  Additional:${ADD_FLAGS}"
echo "  All:${FLAGS}"

mkdir -p /var/run/s6/container_environment
printf '%s' "${FLAGS}" > /var/run/s6/container_environment/PUREFTPD_FLAGS
