#!/usr/bin/with-contenv sh
# shellcheck shell=sh
# shellcheck enable=require-variable-braces

TZ=${TZ:-UTC}
CONTAINER_IP="$(ip a show dev "$(ip r show default | awk '{print$5}')" | sed -nr 's%.*inet ([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3})/[0-9]{1,2} .*%\1%p')"
SECURE_MODE=${SECURE_MODE:-true}
ACTIVE_PORT=${ACTIVE_PORT:-21000}
PASSIVE_IP=${PASSIVE_IP:-${CONTAINER_IP}}
PASSIVE_PORT_RANGE=${PASSIVE_PORT_RANGE:-21001:21011}

extractFromConf() {
  awk -F' ' "/^${1}/ {print\$2}" < "${2}"
}

PFTPD_FLAGS="/pure-ftpd/data/pureftpd.flags"
PFTPD_PUREDB="/pure-ftpd/data/pureftpd.pdb"
PFTPD_PASSWD="/pure-ftpd/data/pureftpd.passwd"
PFTPD_PEM="/pure-ftpd/data/pureftpd.pem"
PFTPD_DHPARAMS="/pure-ftpd/data/pureftpd-dhparams.pem"

[ -d /pure-ftpd/data ] || mkdir -p /pure-ftpd/data
[ -d /pure-ftpd/ftp ] || mkdir -p /pure-ftpd/ftp
[ -d /pure-ftpd/ssl ] || mkdir -p /pure-ftpd/ssl

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

if [ -n "${PASSIVE_IP}" ]; then
  FLAGS="${FLAGS} --forcepassiveip ${PASSIVE_IP}"
fi

# Secure mode
SECURE_FLAGS=""
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

# Timezone
echo "Setting timezone to ${TZ}..."
ln -snf "/usr/share/zoneinfo/${TZ}" /etc/localtime
echo "${TZ}" > /etc/timezone

FLAGS="${FLAGS} --login puredb:${PFTPD_PUREDB}"
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

echo "Flags"
echo "  Secure: ${SECURE_FLAGS}"
echo "  Additional: ${ADD_FLAGS}"
echo "  All: ${FLAGS}"

printf '%s' "${FLAGS}" > /var/run/s6/container_environment/PUREFTPD_FLAGS
