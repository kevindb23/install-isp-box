#!/usr/bin/env bash
# Remove FreeRADIUS 3.0, its configuration, and the installer-created RADIUS database.

set -Eeuo pipefail
IFS=$'\n\t'

RADIUS_DB_NAME="${RADIUS_DB_NAME:-radius}"
RADIUS_DB_USER="${RADIUS_DB_USER:-raduser}"
ASSUME_YES=0

usage() {
    cat <<'EOF'
Usage: uninstall-freeradius-jammy.sh [--yes]

  --yes    Do not ask for confirmation.

This removes FreeRADIUS packages/configuration, the RADIUS database, and the
dedicated RADIUS SQL user. It does not remove MySQL/MariaDB or other databases.
EOF
}

for arg in "$@"; do
    case "${arg}" in
        --yes) ASSUME_YES=1 ;;
        --help|-h) usage; exit 0 ;;
        *) printf 'Unknown option: %s\n' "${arg}" >&2; usage >&2; exit 2 ;;
    esac
done

[[ "${EUID}" -eq 0 ]] || { printf 'Run as root: sudo bash %s\n' "$0" >&2; exit 1; }
command -v apt-get >/dev/null 2>&1 || { printf 'This script requires Ubuntu with apt-get.\n' >&2; exit 1; }
command -v mysql >/dev/null 2>&1 || { printf 'The mysql client is required to remove the RADIUS database.\n' >&2; exit 1; }
[[ "${RADIUS_DB_NAME}" =~ ^[A-Za-z0-9_]+$ ]] || { printf 'Invalid RADIUS_DB_NAME.\n' >&2; exit 1; }
[[ "${RADIUS_DB_USER}" =~ ^[A-Za-z0-9_]+$ ]] || { printf 'Invalid RADIUS_DB_USER.\n' >&2; exit 1; }

if [[ "${ASSUME_YES}" -ne 1 ]]; then
    printf 'This permanently removes FreeRADIUS, database `%s`, and SQL user `%s`. Continue? [y/N] ' "${RADIUS_DB_NAME}" "${RADIUS_DB_USER}"
    read -r answer
    [[ "${answer}" =~ ^[Yy]$ ]] || { printf 'Cancelled.\n'; exit 0; }
fi

if command -v systemctl >/dev/null 2>&1; then
    systemctl disable --now freeradius 2>/dev/null || true
fi

mysql --protocol=socket -uroot <<SQL
DROP DATABASE IF EXISTS \`${RADIUS_DB_NAME}\`;
DROP USER IF EXISTS '${RADIUS_DB_USER}'@'localhost';
FLUSH PRIVILEGES;
SQL

apt-get purge -y freeradius freeradius-common freeradius-config freeradius-mysql freeradius-utils
apt-get autoremove -y
rm -rf -- /etc/freeradius /var/log/freeradius

printf 'FreeRADIUS, its configuration, database, and dedicated SQL user were removed.\n'
printf 'The MySQL/MariaDB server and other databases were preserved.\n'
