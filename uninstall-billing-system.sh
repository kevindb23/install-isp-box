#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

readonly SCRIPT_URL="${SCRIPT_URL:-https://raw.githubusercontent.com/kevindb23/install-isp-box/main/uninstall-billing-server.sh}"
readonly WORK_DIR="$(mktemp -d -t uninstall-billing-system.XXXXXX)"
trap 'rm -rf "${WORK_DIR}"' EXIT

usage() {
    cat <<'EOF'
Usage: sudo bash uninstall-billing-system.sh [--yes] [--purge-database]

Downloads and runs the billing system uninstaller.
The application and billing-specific Nginx configuration are removed.
Shared packages are preserved. The database is preserved unless
--purge-database is supplied with DB_NAME and DB_USER.

Environment:
  SCRIPT_URL  Uninstaller URL; normally leave unchanged.
  APP_DIR     Install directory; default: /var/www/billing-server
  DB_NAME     Database to remove with --purge-database
  DB_USER     MySQL user to remove with --purge-database
EOF
}

for arg in "$@"; do
    case "${arg}" in
        -h|--help) usage; exit 0 ;;
        --yes|--purge-database) ;;
        *) printf 'Unknown option: %s\n' "${arg}" >&2; usage >&2; exit 2 ;;
    esac
done

[[ "${EUID}" -eq 0 ]] || { command -v sudo >/dev/null 2>&1 || { echo 'Run as root or install sudo.' >&2; exit 1; }; }
if [[ "${EUID}" -eq 0 ]]; then
    apt-get update -y
    apt-get install -y ca-certificates curl
    bash_cmd=(bash)
else
    sudo apt-get update -y
    sudo apt-get install -y ca-certificates curl
    bash_cmd=(sudo bash)
fi

curl --fail --silent --show-error --location "${SCRIPT_URL}" -o "${WORK_DIR}/uninstall-billing-server.sh"
chmod 700 "${WORK_DIR}/uninstall-billing-server.sh"
"${bash_cmd[@]}" "${WORK_DIR}/uninstall-billing-server.sh" "$@"

# Restore the stock Ubuntu Nginx site and document root after billing removal.
install -d -m 0755 /var/www/html
if [[ -f /etc/nginx/sites-available/default ]]; then
    ln -sfn /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default
fi
nginx -t
systemctl enable --now nginx
systemctl reload nginx
printf '[billing-system] Billing removed; Nginx restored to /var/www/html.\n'
