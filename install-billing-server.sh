#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

readonly BILLING_SQL_FILE="${BILLING_SQL_FILE:-}"

SKIP_BUILD=0
SETUP_DATABASE=0

usage() {
    cat <<'EOF'
Usage: sudo bash install-billing-server.sh [options]

Options:
  --skip-build       Install dependencies but do not build frontends.
  --setup-database   Create the database/user from DB_NAME, DB_USER, DB_PASSWORD.
  -h, --help         Show this help.

Environment:
  SERVER_NAME        Nginx server_name; default: _.
EOF
}

for arg in "$@"; do
    case "$arg" in
        --skip-build) SKIP_BUILD=1 ;;
        --setup-database) SETUP_DATABASE=1 ;;
        -h|--help) usage; exit 0 ;;
        *) printf 'Unknown option: %s\n' "$arg" >&2; usage >&2; exit 2 ;;
    esac
done

fail() { printf '[billing-server] ERROR: %s\n' "$*" >&2; exit 1; }
trap 'fail "Installation failed near line ${LINENO}."' ERR

[[ "${EUID}" -eq 0 ]] || { command -v sudo >/dev/null 2>&1 || fail "Run as root or install sudo."; SUDO=(sudo); }
SUDO="${SUDO:-}"
if [[ "${EUID}" -eq 0 ]]; then run_root() { "$@"; }; else run_root() { sudo "$@"; }; fi

[[ -r /etc/os-release ]] || fail "Cannot identify the operating system."
# shellcheck disable=SC1091
source /etc/os-release
[[ "${ID:-}" == "ubuntu" || "${ID:-}" == "debian" ]] || fail "Ubuntu or Debian is required."

export DEBIAN_FRONTEND=noninteractive
run_root apt-get update
run_root apt-get install -y ca-certificates curl git unzip nginx mysql-server \
    php-cli php-fpm php-common php-mysql php-curl php-mbstring php-xml php-zip \
    python3 python3-pip composer

PHP_MM="$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;')"
PHP_MAJOR="${PHP_MM%%.*}"
PHP_MINOR="${PHP_MM##*.}"
(( PHP_MAJOR > 8 || (PHP_MAJOR == 8 && PHP_MINOR >= 1) )) || fail "PHP 8.1+ required; found ${PHP_MM}."
command -v composer >/dev/null 2>&1 || fail "Composer installation failed."
command -v python3 >/dev/null 2>&1 || fail "Python 3 installation failed."

if command -v node >/dev/null 2>&1; then
    NODE_MAJOR="$(node --version | sed 's/^v//' | cut -d. -f1)"
else
    NODE_MAJOR=0
fi
if (( NODE_MAJOR < 18 )); then
    run_root apt-get remove -y npm libnode-dev >/dev/null 2>&1 || true
    curl --fail --silent --show-error --location https://deb.nodesource.com/setup_20.x | run_root bash -
    run_root apt-get install -y nodejs
    NODE_MAJOR="$(node --version | sed 's/^v//' | cut -d. -f1)"
fi
(( NODE_MAJOR >= 18 )) || fail "Node.js 18+ required; found $(node --version)."

if (( SETUP_DATABASE == 1 )); then
    : "${DB_NAME:?DB_NAME is required with --setup-database}"
    : "${DB_USER:?DB_USER is required with --setup-database}"
    : "${DB_PASSWORD:?DB_PASSWORD is required with --setup-database}"
    [[ "${DB_NAME}" =~ ^[A-Za-z0-9_]+$ ]] || fail "DB_NAME contains invalid characters."
    [[ "${DB_USER}" =~ ^[A-Za-z0-9_]+$ ]] || fail "DB_USER contains invalid characters."
    DB_PASSWORD_SQL="${DB_PASSWORD//\\/\\\\}"
    DB_PASSWORD_SQL="${DB_PASSWORD_SQL//\'/\'\'}"
    run_root mysql --protocol=socket -uroot <<SQL
CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASSWORD_SQL}';
ALTER USER '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASSWORD_SQL}';
GRANT ALL PRIVILEGES ON *.* TO '${DB_USER}'@'localhost' WITH GRANT OPTION;
FLUSH PRIVILEGES;
SQL
    if [[ -n "${BILLING_SQL_FILE}" ]]; then
        [[ -f "${BILLING_SQL_FILE}" ]] || fail "Database dump not found: ${BILLING_SQL_FILE}."
        run_root mysql --protocol=socket -uroot "${DB_NAME}" < "${BILLING_SQL_FILE}"
    fi
    if [[ -n "${ADMIN_USERNAME:-}" && -n "${ADMIN_PASSWORD:-}" ]]; then
        ADMIN_PASSWORD_HASH="$(php -r 'echo password_hash($argv[1], PASSWORD_DEFAULT);' "${ADMIN_PASSWORD}")"
        ADMIN_USERNAME_SQL="${ADMIN_USERNAME//\'/\'\'}"
        run_root mysql --protocol=socket -uroot "${DB_NAME}" <<SQL
DELETE FROM users WHERE role = 'SUPERADMIN';
INSERT INTO users (username, full_name, email, password, role, status)
VALUES ('${ADMIN_USERNAME_SQL}', 'System Administrator', '${ADMIN_USERNAME_SQL}@localhost', '${ADMIN_PASSWORD_HASH}', 'SUPERADMIN', 'ACTIVE');
SQL
    fi
fi

run_root systemctl enable --now mysql "php${PHP_MM}-fpm"

printf '[billing-server] Server dependencies and MySQL setup completed.\n'
