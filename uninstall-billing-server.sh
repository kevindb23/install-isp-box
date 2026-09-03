#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

readonly APP_DIR="${APP_DIR:-/var/www/billing-server}"
readonly NGINX_SITE="/etc/nginx/sites-available/billing-server"
readonly NGINX_LINK="/etc/nginx/sites-enabled/billing-server"
ASSUME_YES=0
PURGE_DATABASE=0

usage() {
    cat <<'EOF'
Usage: sudo bash uninstall-billing-server.sh [options]

Options:
  --yes               Do not ask for confirmation.
  --purge-database    Also drop DB_NAME and DB_USER (requires both variables).
  -h, --help          Show this help.
EOF
}

for arg in "$@"; do
    case "$arg" in
        --yes) ASSUME_YES=1 ;;
        --purge-database) PURGE_DATABASE=1 ;;
        -h|--help) usage; exit 0 ;;
        *) printf 'Unknown option: %s\n' "$arg" >&2; usage >&2; exit 2 ;;
    esac
done

[[ "${EUID}" -eq 0 ]] || { printf 'Run as root: sudo bash %s\n' "$0" >&2; exit 1; }
command -v apt-get >/dev/null 2>&1 || { printf 'This script requires apt-get.\n' >&2; exit 1; }

if [[ "${ASSUME_YES}" -ne 1 ]]; then
    printf 'This will remove %s and its Nginx deployment. Continue? [y/N] ' "${APP_DIR}"
    read -r answer
    [[ "${answer}" =~ ^[Yy]$ ]] || { printf 'Cancelled.\n'; exit 0; }
fi

if (( PURGE_DATABASE == 1 )); then
    : "${DB_NAME:?DB_NAME is required with --purge-database}"
    : "${DB_USER:?DB_USER is required with --purge-database}"
    [[ "${DB_NAME}" =~ ^[A-Za-z0-9_]+$ ]] || { printf 'Invalid DB_NAME.\n' >&2; exit 1; }
    [[ "${DB_USER}" =~ ^[A-Za-z0-9_]+$ ]] || { printf 'Invalid DB_USER.\n' >&2; exit 1; }
fi

rm -f -- "${NGINX_LINK}" "${NGINX_SITE}"
if [[ -e /etc/nginx/sites-enabled/default.disabled && ! -e /etc/nginx/sites-enabled/default ]]; then
    mv /etc/nginx/sites-enabled/default.disabled /etc/nginx/sites-enabled/default
fi
nginx -t 2>/dev/null && systemctl reload nginx 2>/dev/null || true

if (( PURGE_DATABASE == 1 )); then
    mysql --protocol=socket -uroot <<SQL
DROP DATABASE IF EXISTS \`${DB_NAME}\`;
DROP USER IF EXISTS '${DB_USER}'@'localhost';
FLUSH PRIVILEGES;
SQL
fi

rm -rf -- "${APP_DIR}"
systemctl daemon-reload 2>/dev/null || true
apt-get autoremove -y

printf '[billing-server] Application files and Nginx configuration removed.\n'
if (( PURGE_DATABASE == 0 )); then
    printf '[billing-server] MySQL database and shared packages were preserved.\n'
fi
