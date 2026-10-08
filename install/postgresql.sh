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

# MemTotal is slightly below marketed RAM; allow for kernel reservations.
MEMORY_MB=$(awk '/^MemTotal:/ {print int($2 / 1024)}' /proc/meminfo)
if [[ ! ${MEMORY_MB} =~ ^[0-9]+$ ]] || (( MEMORY_MB < 512 )); then
  echo "Error: at least 512 MiB of memory is required" >&2
  exit 1
fi

# These are conservative starting points for a shared application server.
# work_mem applies per operation/worker, not per connection.
if (( MEMORY_MB >= 120 * 1024 )); then
  MEMORY_PROFILE='128 GiB class'
  SHARED_BUFFERS_MB=16384
  EFFECTIVE_CACHE_MB=49152
  WORK_MEM_MB=32
  MAINTENANCE_MEM_MB=1024
elif (( MEMORY_MB >= 22 * 1024 )); then
  MEMORY_PROFILE='24 GiB class'
  SHARED_BUFFERS_MB=2048
  EFFECTIVE_CACHE_MB=4096
  WORK_MEM_MB=32
  MAINTENANCE_MEM_MB=1024
else
  MEMORY_PROFILE='small server (scaled)'
  SHARED_BUFFERS_MB=$(( MEMORY_MB / 8 ))
  EFFECTIVE_CACHE_MB=$(( MEMORY_MB / 4 ))
  WORK_MEM_MB=$(( MEMORY_MB / 1024 ))
  (( WORK_MEM_MB >= 1 )) || WORK_MEM_MB=1
  MAINTENANCE_MEM_MB=$(( MEMORY_MB / 32 ))
fi

# WAL depends on write volume and disk space, not RAM alone. Cap at the
# notes' 2 GiB / 1 GiB baseline; reduce it on small machines.
MAX_WAL_MB=$(( MEMORY_MB / 8 ))
(( MAX_WAL_MB >= 256 )) || MAX_WAL_MB=256
(( MAX_WAL_MB <= 2048 )) || MAX_WAL_MB=2048
MIN_WAL_MB=$(( MAX_WAL_MB / 2 ))

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

cat > "${PG_CONFIG_DIR}/conf.d/90-server-tuning.conf" <<EOF
# Managed by postgresql.sh. Detected RAM: ${MEMORY_MB} MiB.
idle_in_transaction_session_timeout = '30min'
idle_session_timeout = '30min'
statement_timeout = '10min'
# TCP keepalives have no effect on Unix-domain sockets.
tcp_keepalives_idle = 120
tcp_keepalives_interval = 30
tcp_keepalives_count = 10
client_connection_check_interval = '100s'
log_min_duration_statement = '800ms'

shared_buffers = '${SHARED_BUFFERS_MB}MB'
effective_cache_size = '${EFFECTIVE_CACHE_MB}MB'
work_mem = '${WORK_MEM_MB}MB'
maintenance_work_mem = '${MAINTENANCE_MEM_MB}MB'

# max_wal_size is a soft checkpoint target, not a disk usage limit.
max_wal_size = '${MAX_WAL_MB}MB'
min_wal_size = '${MIN_WAL_MB}MB'
checkpoint_timeout = '15min'
checkpoint_completion_target = 0.9
fsync = on
synchronous_commit = on
random_page_cost = 1.5
seq_page_cost = 1.0
io_method = worker
io_workers = 4

log_destination = 'stderr'
logging_collector = on
log_directory = '/var/log/postgresql'
log_filename = 'postgresql.log'
# Fixed filename: reopening every 3 days does not limit retention.
# Actual rotation/retention is managed by postgresql-common logrotate.
log_rotation_age = '3d'
log_truncate_on_rotation = off
EOF

PG_PROFILE=/var/lib/postgresql/.bash_profile
touch "${PG_PROFILE}"
chown postgres:postgres "${PG_PROFILE}"
chmod 600 "${PG_PROFILE}"
# TMOUT affects an idle interactive Bash prompt, not a running psql process.
if ! grep -qx 'export TMOUT=600' "${PG_PROFILE}"; then
  printf '\nexport TMOUT=600\n' >> "${PG_PROFILE}"
fi

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

printf '\nPostgreSQL installation report\n'
printf 'Detected RAM: %s MiB; memory profile: %s\n' "${MEMORY_MB}" "${MEMORY_PROFILE}"
printf 'Shell: %s (TMOUT=600)\n' "${PG_PROFILE}"
printf 'Local authentication: local all all trust\n'
printf 'Log retention: /etc/logrotate.d/postgresql-common (3d is not retention)\n'
pg_lsclusters
runuser -u postgres -- psql -X -v ON_ERROR_STOP=1 -P pager=off -d postgres <<'SQL'
SELECT name, setting, unit, sourcefile, pending_restart
FROM pg_settings
WHERE name IN (
  'server_version', 'data_directory', 'config_file', 'hba_file',
  'listen_addresses', 'unix_socket_directories', 'data_checksums',
  'idle_in_transaction_session_timeout', 'idle_session_timeout',
  'statement_timeout', 'tcp_keepalives_idle', 'tcp_keepalives_interval',
  'tcp_keepalives_count', 'client_connection_check_interval',
  'log_min_duration_statement', 'shared_buffers', 'effective_cache_size',
  'work_mem', 'maintenance_work_mem', 'max_connections',
  'max_wal_size', 'min_wal_size', 'checkpoint_timeout',
  'checkpoint_completion_target', 'wal_writer_delay', 'wal_writer_flush_after',
  'fsync', 'synchronous_commit', 'random_page_cost', 'seq_page_cost',
  'io_method', 'io_workers', 'log_destination', 'logging_collector',
  'log_directory', 'log_filename', 'log_rotation_age', 'log_truncate_on_rotation'
)
ORDER BY name;
SELECT pg_current_logfile() AS current_log_file;
SQL
echo "PostgreSQL ${PG_VERSION} installation and verification completed."
