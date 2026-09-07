#!/usr/bin/env bash
# Install FreeRADIUS 3.0 with MySQL support on Ubuntu Jammy 22.04.

set -Eeuo pipefail
IFS=$'\n\t'


log() {
    printf '[freeradius] %s\n' "$*"
}

die() {
    printf '[freeradius] ERROR: %s\n' "$*" >&2
    exit 1
}

trap 'die "Installation failed near line ${LINENO}."' ERR

[[ "${EUID}" -eq 0 ]] || die "Run this script as root, for example: sudo bash $0"
command -v apt-get >/dev/null 2>&1 || die "This installer requires Ubuntu with apt-get."
[[ -r /etc/os-release ]] || die "Cannot identify the operating system."
# shellcheck disable=SC1091
source /etc/os-release
[[ "${ID:-}" == "ubuntu" ]] || die "This installer supports Ubuntu only. Detected: ${ID:-unknown}."
[[ "${VERSION_ID:-}" == "22.04" ]] || die "This installer targets Ubuntu Jammy 22.04. Detected: ${VERSION_ID:-unknown}."
[[ "$(dpkg --print-architecture)" == "amd64" ]] || die "This installer supports amd64 only."

export DEBIAN_FRONTEND=noninteractive

log "Installing repository prerequisites."
apt-get update
apt-get install -y ca-certificates curl mysql-client

log "Refreshing APT metadata."
apt-get update

log "Installing Ubuntu FreeRADIUS 3.0 packages with MySQL support."
apt-get install -y freeradius freeradius-utils freeradius-mysql mysql-client

command -v mysql >/dev/null 2>&1 || die "The mysql client is required for RADIUS database setup."

RADIUS_DB_NAME="${RADIUS_DB_NAME:-radius}"
RADIUS_DB_USER="${RADIUS_DB_USER:-raduser}"
RADIUS_DB_PASSWORD="${RADIUS_DB_PASSWORD:-radpasswd}"
RADIUS_DB_HOST="${RADIUS_DB_HOST:-localhost}"
RADIUS_DB_PORT="${RADIUS_DB_PORT:-3306}"
RADIUS_SCHEMA_URL="${RADIUS_SCHEMA_URL:-https://raw.githubusercontent.com/kevindb23/install-isp-box/main/radius.sql}"

log "Creating the RADIUS database and SQL account."
DB_PASSWORD_SQL="${RADIUS_DB_PASSWORD//\\/\\\\}"
DB_PASSWORD_SQL="${DB_PASSWORD_SQL//\'/\'\'}"
mysql --protocol=socket -uroot <<SQL
CREATE DATABASE IF NOT EXISTS \`${RADIUS_DB_NAME}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '${RADIUS_DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASSWORD_SQL}';
ALTER USER '${RADIUS_DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASSWORD_SQL}';
GRANT ALL PRIVILEGES ON \`${RADIUS_DB_NAME}\`.* TO '${RADIUS_DB_USER}'@'localhost';
FLUSH PRIVILEGES;
SQL

SCHEMA_FILE="$(mktemp /tmp/radius-schema.XXXXXX.sql)"
trap 'rm -f "${SCHEMA_FILE}"; die "Installation failed near line ${LINENO}."' ERR
log "Downloading the repository RADIUS schema."
curl --fail --silent --show-error --location "${RADIUS_SCHEMA_URL}" -o "${SCHEMA_FILE}"
[[ -s "${SCHEMA_FILE}" ]] || die "The repository RADIUS schema download was empty."
mysql --protocol=socket -uroot "${RADIUS_DB_NAME}" < "${SCHEMA_FILE}"
rm -f "${SCHEMA_FILE}"

SQL_CONF=""
for candidate in /etc/freeradius/3.0/mods-available/sql /etc/freeradius/sql.conf; do
    if [[ -f "${candidate}" ]]; then
        SQL_CONF="${candidate}"
        break
    fi
done
[[ -n "${SQL_CONF}" ]] || die "FreeRADIUS SQL configuration was not found."
sed -i \
    -e 's|^[[:space:]]*driver[[:space:]]*=.*|driver = "rlm_sql_mysql"|' \
    -e "s|^[[:space:]]*server[[:space:]]*=.*|server = \"${RADIUS_DB_HOST}\"|" \
    -e "s|^[[:space:]]*port[[:space:]]*=.*|port = ${RADIUS_DB_PORT}|" \
    -e "s|^[[:space:]]*login[[:space:]]*=.*|login = \"${RADIUS_DB_USER}\"|" \
    -e "s|^[[:space:]]*password[[:space:]]*=.*|password = \"${DB_PASSWORD_SQL}\"|" \
    -e "s|^[[:space:]]*radius_db[[:space:]]*=.*|radius_db = \"${RADIUS_DB_NAME}\"|" \
    "${SQL_CONF}"
# Ubuntu's packaged SQL module may reference a non-existent example CA file.
# Use the system CA bundle so FreeRADIUS can parse the module on a fresh host.
if [[ -f /etc/ssl/certs/ca-certificates.crt ]]; then
    sed -i 's|^[[:space:]]*ca_file[[:space:]]*=.*|ca_file = /etc/ssl/certs/ca-certificates.crt|' "${SQL_CONF}"
    # Also repair included module files and symlink targets carrying the
    # package's example CA path.
    FREERADIUS_CONFIG_ROOT="/etc/freeradius/3.0"
    [[ -d "${FREERADIUS_CONFIG_ROOT}" ]] || FREERADIUS_CONFIG_ROOT="/etc/freeradius"
    while IFS= read -r -d '' config_file; do
        sed -i 's|^[[:space:]]*ca_file[[:space:]]*=.*|ca_file = /etc/ssl/certs/ca-certificates.crt|' "${config_file}"
    done < <(find "${FREERADIUS_CONFIG_ROOT}" -type f -name '*.conf' -print0 2>/dev/null)
fi
# The Ubuntu example SQL module can also contain client-certificate paths
# that are not installed. They are optional for password-authenticated MySQL.
sed -i -E \
    's@^([[:space:]]*)(certificate_file|private_key_file)[[:space:]]*=.*@\1# \2 disabled: no client TLS certificate configured@' \
    "${SQL_CONF}"
RADIUSD_CONF="/etc/freeradius/3.0/radiusd.conf"
[[ -f "${RADIUSD_CONF}" ]] || RADIUSD_CONF="/etc/freeradius/radiusd.conf"
[[ -f "${RADIUSD_CONF}" ]] || die "FreeRADIUS configuration was not found at ${RADIUSD_CONF}."
SITE="/etc/freeradius/3.0/sites-available/default"
[[ -f "${SITE}" ]] || SITE="/etc/freeradius/sites-available/default"
[[ -f "${SITE}" ]] || die "FreeRADIUS default site was not found at ${SITE}."
if [[ "${SQL_CONF}" == */mods-available/sql ]]; then
    mkdir -p /etc/freeradius/3.0/mods-enabled
    ln -sfn ../mods-available/sql /etc/freeradius/3.0/mods-enabled/sql
else
    grep -Eq '^[[:space:]]*\$INCLUDE[[:space:]]+sql\.conf' "${RADIUSD_CONF}" || printf '\n\$INCLUDE sql.conf\n' >> "${RADIUSD_CONF}"
    sed -i '/^[[:space:]]*#*[[:space:]]*sql[[:space:]]*$/s/^[[:space:]]*#*[[:space:]]*/        /' "${SITE}"
fi

log "Verifying the seven core RADIUS SQL tables."
TABLE_COUNT="$(mysql --protocol=socket -u"${RADIUS_DB_USER}" -p"${RADIUS_DB_PASSWORD}" -N -B "${RADIUS_DB_NAME}" -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='${RADIUS_DB_NAME}' AND table_name IN ('radacct','radcheck','radgroupcheck','radgroupreply','radpostauth','radreply','radusergroup');")"
[[ "${TABLE_COUNT}" == "7" ]] || die "Expected seven core RADIUS SQL tables, found ${TABLE_COUNT}."

log "Validating the FreeRADIUS configuration."
freeradius -XC >/dev/null || die "FreeRADIUS configuration validation failed. Run 'freeradius -XC' for details."

if command -v systemctl >/dev/null 2>&1 && systemctl list-unit-files freeradius.service >/dev/null 2>&1; then
    log "Enabling and restarting the FreeRADIUS service."
    systemctl enable freeradius
    systemctl stop freeradius >/dev/null 2>&1 || true
    systemctl kill --kill-who=all --signal=TERM freeradius >/dev/null 2>&1 || true
    systemctl reset-failed freeradius >/dev/null 2>&1 || true
    for wait_attempt in 1 2 3 4 5; do
        systemctl is-active --quiet freeradius || break
        sleep 1
    done
    started=0
    for attempt in 1 2 3 4 5; do
        if systemctl start freeradius; then
            started=1
            break
        fi
        systemctl stop freeradius >/dev/null 2>&1 || true
        systemctl kill --kill-who=all --signal=TERM freeradius >/dev/null 2>&1 || true
        systemctl reset-failed freeradius >/dev/null 2>&1 || true
        sleep 3
    done
    if [[ "${started}" -ne 1 ]]; then
        journalctl -u freeradius --no-pager -n 40 >&2 || true
        die "FreeRADIUS failed to start after configuration validation."
    fi
    systemctl --no-pager --full status freeradius || true
else
    log "FreeRADIUS was installed. Start it with: systemctl enable --now freeradius"
fi

log "Installation completed. Existing /etc/freeradius configuration was preserved."
