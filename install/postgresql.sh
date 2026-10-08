#!/usr/bin/env bash
set -Eeuo pipefail

if [[ ${EUID} -ne 0 ]]; then
  echo "Error: run this script as root" >&2
  exit 1
fi

if [[ ! -r /etc/os-release ]]; then
  echo "Error: /etc/os-release is missing" >&2
  exit 1
fi

. /etc/os-release
if [[ ${ID} != debian && ${ID} != ubuntu ]]; then
  echo "Error: this installer supports Debian and Ubuntu only" >&2
  exit 1
fi

PG_VERSION=18
PG_CLUSTER=main
PG_DATA_DIR=/var/lib/postgresql/18
PG_CONFIG_DIR=/etc/postgresql/18/main
PGDG_KEY=/usr/share/postgresql-common/pgdg/apt.postgresql.org.asc
PGDG_LIST=/etc/apt/sources.list.d/pgdg.list

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Error: required command is missing: $1" >&2
    exit 1
  fi
}

for command in apt-get; do
  require_command "$command"
done

apt-get update
apt-get install -y curl ca-certificates gnupg postgresql-common

for command in curl install sed grep awk systemctl runuser; do
  require_command "$command"
done

install -d -m 0755 /usr/share/postgresql-common/pgdg
if [[ ! -s ${PGDG_KEY} ]]; then
  curl --fail --silent --show-error --location \
    https://www.postgresql.org/media/keys/ACCC4CF8.asc \
    -o "${PGDG_KEY}"
  chmod 0644 "${PGDG_KEY}"
fi

printf 'deb [signed-by=%s] https://apt.postgresql.org/pub/repos/apt %s-pgdg main\n' \
  "${PGDG_KEY}" "${VERSION_CODENAME}" > "${PGDG_LIST}"
apt-get update
apt-get install -y "postgresql-${PG_VERSION}"

for command in pg_lsclusters pg_createcluster psql mktemp; do
  require_command "$command"
done

if ! pg_lsclusters | awk 'NR > 1 {print $1, $2}' | grep -qx "${PG_VERSION} ${PG_CLUSTER}"; then
  /usr/bin/pg_createcluster "${PG_VERSION}" "${PG_CLUSTER}" \
    --datadir="${PG_DATA_DIR}" \
    --start \
    -- --data-checksums
fi

if [[ ! -d ${PG_CONFIG_DIR} ]]; then
  echo "Error: PostgreSQL cluster configuration was not created: ${PG_CONFIG_DIR}" >&2
  exit 1
fi

install -d -m 0755 "${PG_CONFIG_DIR}/conf.d"
cat > "${PG_CONFIG_DIR}/conf.d/00-local-only.conf" <<'EOF'
# Managed by postgresql.sh: local Unix-domain-socket access only.
listen_addresses = ''
unix_socket_directories = '/var/run/postgresql'
EOF

PG_HBA="${PG_CONFIG_DIR}/pg_hba.conf"
if ! grep -q '^# BEGIN postgresql.sh local trust$' "${PG_HBA}"; then
  hba_tmp=$(mktemp)
  trap 'rm -f "${hba_tmp:-}"' EXIT
  {
    echo '# BEGIN postgresql.sh local trust'
    echo 'local   all             all                                     trust'
    echo '# END postgresql.sh local trust'
    cat "${PG_HBA}"
  } > "${hba_tmp}"
  install -o postgres -g postgres -m 0640 "${hba_tmp}" "${PG_HBA}"
  rm -f "${hba_tmp}"
  trap - EXIT
fi

systemctl enable --now "postgresql@${PG_VERSION}-${PG_CLUSTER}.service"
systemctl restart "postgresql@${PG_VERSION}-${PG_CLUSTER}.service"

if ! runuser -u postgres -- psql -X -v ON_ERROR_STOP=1 -d postgres \
  -c "SELECT version();" \
  -c "SHOW listen_addresses;" \
  -c "SHOW data_checksums;"; then
  echo "Error: PostgreSQL verification failed" >&2
  exit 1
fi

if [[ $(runuser -u postgres -- psql -X -At -d postgres -c 'SHOW listen_addresses;') != "" ]]; then
  echo "Error: PostgreSQL is still configured to listen on TCP" >&2
  exit 1
fi

if [[ $(runuser -u postgres -- psql -X -At -d postgres -c 'SHOW data_checksums;') != on ]]; then
  echo "Error: data checksums are not enabled" >&2
  exit 1
fi

echo "PostgreSQL ${PG_VERSION} is installed with Unix-socket-only access and data checksums enabled."
