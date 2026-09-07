#!/usr/bin/env bash
# Install FreeRADIUS 3.2 on Ubuntu Jammy 22.04 from InkBridge Networks.
# Based on: https://packages.inkbridgenetworks.com/#fr32-ubuntu-jammy

set -Eeuo pipefail
IFS=$'\n\t'

readonly KEYRING_DIR="/etc/apt/keyrings"
readonly KEYRING_FILE="${KEYRING_DIR}/packages.networkradius.com.asc"
readonly SOURCE_FILE="/etc/apt/sources.list.d/inkbridge.list"
readonly PREFERENCES_FILE="/etc/apt/preferences.d/networkradius"
readonly KEY_URL="https://packages.inkbridgenetworks.com/pgp/packages.networkradius.com.asc"
readonly REPOSITORY_URL="http://packages.inkbridgenetworks.com/freeradius-3.2/ubuntu/jammy"

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
[[ "$(dpkg --print-architecture)" == "amd64" ]] || die "The InkBridge Jammy repository is configured for amd64 only."

export DEBIAN_FRONTEND=noninteractive

log "Installing repository prerequisites."
apt-get update
apt-get install -y ca-certificates curl mysql-client

log "Installing the InkBridge Networks package signing key."
install -d -o root -g root -m 0755 "${KEYRING_DIR}"
curl --fail --silent --show-error --location "${KEY_URL}" \
    | install -o root -g root -m 0644 /dev/stdin "${KEYRING_FILE}"

log "Configuring the InkBridge Networks APT repository."
cat > "${PREFERENCES_FILE}" <<'EOF'
Package: /freeradius/
Pin: origin "packages.inkbridgenetworks.com"
Pin-Priority: 999
EOF
chmod 0644 "${PREFERENCES_FILE}"

cat > "${SOURCE_FILE}" <<EOF
deb [arch=amd64 signed-by=${KEYRING_FILE}] ${REPOSITORY_URL} jammy main
EOF
chmod 0644 "${SOURCE_FILE}"

log "Refreshing APT metadata."
apt-get update

log "Installing FreeRADIUS 3.2 packages with MySQL support."
apt-get install -y freeradius freeradius-utils freeradius-mysql

RADIUS_VERSION="$(freeradius -v 2>/dev/null | sed -n 's/.*FreeRADIUS Version \([0-9][0-9.]*\).*/\1/p' | head -n1)"
[[ "${RADIUS_VERSION}" == 3.2.* ]] || die "FreeRADIUS 3.2 was not installed. Detected version: ${RADIUS_VERSION:-unknown}. Check the InkBridge APT repository and pinning."
log "Verified FreeRADIUS version ${RADIUS_VERSION}."

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

SCHEMA_FILE=""
for candidate in \
    /etc/freeradius/3.2/mods-config/sql/main/mysql/schema.sql \
    /etc/freeradius/mods-config/sql/main/mysql/schema.sql \
    /etc/freeradius/sql/mysql/schema.sql; do
    if [[ -f "${candidate}" ]]; then SCHEMA_FILE="${candidate}"; break; fi
done
[[ -n "${SCHEMA_FILE}" ]] || die "FreeRADIUS MySQL schema.sql was not found."
mysql --protocol=socket -uroot "${RADIUS_DB_NAME}" < "${SCHEMA_FILE}"

SQL_MODULE="/etc/freeradius/3.2/mods-available/sql"
[[ -f "${SQL_MODULE}" ]] || SQL_MODULE="/etc/freeradius/mods-available/sql"
[[ -f "${SQL_MODULE}" ]] || die "FreeRADIUS SQL module configuration was not found."
sed -i \
    -e 's|^[[:space:]]*driver[[:space:]]*=.*|\tdriver = "rlm_sql_mysql"|' \
    -e "s|^[[:space:]]*server[[:space:]]*=.*|\tserver = \"${RADIUS_DB_HOST}\"|" \
    -e "s|^[[:space:]]*port[[:space:]]*=.*|\tport = ${RADIUS_DB_PORT}|" \
    -e "s|^[[:space:]]*login[[:space:]]*=.*|\tlogin = \"${RADIUS_DB_USER}\"|" \
    -e "s|^[[:space:]]*password[[:space:]]*=.*|\tpassword = \"${DB_PASSWORD_SQL}\"|" \
    -e "s|^[[:space:]]*radius_db[[:space:]]*=.*|\tradius_db = \"${RADIUS_DB_NAME}\"|" \
    "${SQL_MODULE}"
SQL_LINK="$(dirname "${SQL_MODULE}")/../mods-enabled/sql"
ln -sfn "../mods-available/sql" "${SQL_LINK}"

for SITE in /etc/freeradius/3.2/sites-enabled/default /etc/freeradius/sites-enabled/default; do
    if [[ -f "${SITE}" ]]; then
        sed -i '/^[[:space:]]*#*[[:space:]]*sql[[:space:]]*$/s/^[[:space:]]*#*[[:space:]]*/        /' "${SITE}"
    fi
done

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
