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

SCHEMA_FILE="/etc/freeradius/sql/mysql/schema.sql"
[[ -f "${SCHEMA_FILE}" ]] || die "FreeRADIUS MySQL schema.sql was not found at ${SCHEMA_FILE}."
mysql --protocol=socket -uroot "${RADIUS_DB_NAME}" < "${SCHEMA_FILE}"

SQL_CONF="/etc/freeradius/sql.conf"
[[ -f "${SQL_CONF}" ]] || die "FreeRADIUS SQL configuration was not found at ${SQL_CONF}."
sed -i \
    -e 's|^[[:space:]]*driver[[:space:]]*=.*|driver = "rlm_sql_mysql"|' \
    -e "s|^[[:space:]]*server[[:space:]]*=.*|server = \"${RADIUS_DB_HOST}\"|" \
    -e "s|^[[:space:]]*port[[:space:]]*=.*|port = ${RADIUS_DB_PORT}|" \
    -e "s|^[[:space:]]*login[[:space:]]*=.*|login = \"${RADIUS_DB_USER}\"|" \
    -e "s|^[[:space:]]*password[[:space:]]*=.*|password = \"${DB_PASSWORD_SQL}\"|" \
    -e "s|^[[:space:]]*radius_db[[:space:]]*=.*|radius_db = \"${RADIUS_DB_NAME}\"|" \
    "${SQL_CONF}"
RADIUSD_CONF="/etc/freeradius/radiusd.conf"
[[ -f "${RADIUSD_CONF}" ]] || die "FreeRADIUS configuration was not found at ${RADIUSD_CONF}."
grep -Eq '^[[:space:]]*\$INCLUDE[[:space:]]+sql\.conf' "${RADIUSD_CONF}" || printf '\n\$INCLUDE sql.conf\n' >> "${RADIUSD_CONF}"
SITE="/etc/freeradius/sites-available/default"
[[ -f "${SITE}" ]] || die "FreeRADIUS default site was not found at ${SITE}."
sed -i '/^[[:space:]]*#*[[:space:]]*sql[[:space:]]*$/s/^[[:space:]]*#*[[:space:]]*/        /' "${SITE}"

log "Verifying the seven core RADIUS SQL tables."
TABLE_COUNT="$(mysql --protocol=socket -u"${RADIUS_DB_USER}" -p"${RADIUS_DB_PASSWORD}" -N -B "${RADIUS_DB_NAME}" -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='${RADIUS_DB_NAME}' AND table_name IN ('radacct','radcheck','radgroupcheck','radgroupreply','radpostauth','radreply','radusergroup');")"
[[ "${TABLE_COUNT}" == "7" ]] || die "Expected seven core RADIUS SQL tables, found ${TABLE_COUNT}."

if command -v systemctl >/dev/null 2>&1 && systemctl list-unit-files freeradius.service >/dev/null 2>&1; then
    log "Enabling and restarting the FreeRADIUS service."
    systemctl enable freeradius
    systemctl restart freeradius
    systemctl --no-pager --full status freeradius || true
else
    log "FreeRADIUS was installed. Start it with: systemctl enable --now freeradius"
fi

log "Installation completed. Existing /etc/freeradius configuration was preserved."
