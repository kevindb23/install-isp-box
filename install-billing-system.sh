#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

readonly SCRIPT_URL="${SCRIPT_URL:-https://raw.githubusercontent.com/kevindb23/install-isp-box/main/install-billing-server.sh}"
readonly SQL_URL="${SQL_URL:-https://raw.githubusercontent.com/kevindb23/install-isp-box/main/billing.sql}"
readonly DEFAULT_REPOSITORY_URL="${REPOSITORY_URL:-https://github.com/kevindb23/ISP-Box.git}"
readonly BILLING_APP_DIR="${APP_DIR:-/var/www/billing-server}"
readonly BILLING_DOCUMENT_ROOT="${DOCUMENT_ROOT:-/var/www/billing-server/public}"
readonly NGINX_SITE="/etc/nginx/sites-available/billing-server"
readonly NGINX_LINK="/etc/nginx/sites-enabled/billing-server"
readonly WORK_DIR="$(mktemp -d -t billing-system.XXXXXX)"
trap 'rm -rf "${WORK_DIR}"' EXIT

usage() {
    cat <<'EOF'
Usage: sudo bash install-billing-system.sh [--skip-build|--setup-database]

Bootstrap installer for the ISP-Box billing system.
Environment:
  REPOSITORY_URL  Application Git URL; default: https://github.com/kevindb23/ISP-Box.git
  SCRIPT_URL      Installer URL; normally leave unchanged.
  APP_DIR         Install directory; default: /var/www/billing-server
  SERVER_NAME     Nginx server_name; default: _
  APP_DIR         Application directory; default: /var/www/billing-server
  DOCUMENT_ROOT   Nginx document root; default: /var/www/billing-server/public
EOF
}

for arg in "$@"; do
    case "${arg}" in
        -h|--help) usage; exit 0 ;;
        --skip-build|--setup-database) ;;
        *) printf 'Unknown option: %s\n' "${arg}" >&2; usage >&2; exit 2 ;;
    esac
done

[[ "${EUID}" -eq 0 ]] || { command -v sudo >/dev/null 2>&1 || { echo 'Run as root or install sudo.' >&2; exit 1; }; }
if [[ "${EUID}" -eq 0 ]]; then
    apt-get update -y
    apt-get install -y ca-certificates curl git
    bash_cmd=(bash)
else
    sudo apt-get update -y
    sudo apt-get install -y ca-certificates curl git
    bash_cmd=(sudo bash)
fi

curl --fail --silent --show-error --location "${SCRIPT_URL}" -o "${WORK_DIR}/install-billing-server.sh"
curl --fail --silent --show-error --location "${SQL_URL}" -o "${WORK_DIR}/billing.sql"
chmod 700 "${WORK_DIR}/install-billing-server.sh"
if [[ -d "${BILLING_APP_DIR}/.git" ]]; then
    git -C "${BILLING_APP_DIR}" fetch --prune origin
    git -C "${BILLING_APP_DIR}" checkout "${BRANCH:-main}"
    git -C "${BILLING_APP_DIR}" pull --ff-only origin "${BRANCH:-main}"
elif [[ -e "${BILLING_APP_DIR}" ]]; then
    echo "Application directory exists but is not a Git checkout: ${BILLING_APP_DIR}" >&2
    exit 1
else
    install -d -m 0755 "$(dirname "${BILLING_APP_DIR}")"
    git clone --branch "${BRANCH:-main}" --single-branch "${DEFAULT_REPOSITORY_URL}" "${BILLING_APP_DIR}"
fi
if [[ "${EUID}" -eq 0 ]]; then
    read -r -p 'MySQL database name [portal]: ' DB_NAME_INPUT
    read -r -p 'MySQL username: ' DB_USER_INPUT
    read -r -s -p 'MySQL password: ' DB_PASSWORD_INPUT; printf '\n'
    read -r -p 'Web UI superadmin username: ' ADMIN_USERNAME_INPUT
    read -r -s -p 'Web UI superadmin password: ' ADMIN_PASSWORD_INPUT; printf '\n'
else
    read -r -p 'MySQL database name [portal]: ' DB_NAME_INPUT
    read -r -p 'MySQL username: ' DB_USER_INPUT
    read -r -s -p 'MySQL password: ' DB_PASSWORD_INPUT; printf '\n'
    read -r -p 'Web UI superadmin username: ' ADMIN_USERNAME_INPUT
    read -r -s -p 'Web UI superadmin password: ' ADMIN_PASSWORD_INPUT; printf '\n'
fi
DB_NAME_INPUT="${DB_NAME_INPUT:-portal}"
[[ -n "${DB_USER_INPUT}" && -n "${DB_PASSWORD_INPUT}" && -n "${ADMIN_USERNAME_INPUT}" && -n "${ADMIN_PASSWORD_INPUT}" ]] || { echo 'All credentials are required.' >&2; exit 1; }
REPOSITORY_URL="${DEFAULT_REPOSITORY_URL}" APP_DIR="${BILLING_APP_DIR}" DOCUMENT_ROOT="${BILLING_DOCUMENT_ROOT}" DB_NAME="${DB_NAME_INPUT}" DB_USER="${DB_USER_INPUT}" DB_PASSWORD="${DB_PASSWORD_INPUT}" ADMIN_USERNAME="${ADMIN_USERNAME_INPUT}" ADMIN_PASSWORD="${ADMIN_PASSWORD_INPUT}" BILLING_SQL_FILE="${WORK_DIR}/billing.sql" "${bash_cmd[@]}" "${WORK_DIR}/install-billing-server.sh" --setup-database "$@"

chown -R root:root "${BILLING_APP_DIR}"
cd "${BILLING_APP_DIR}"
[[ -f composer.json ]] || { echo "The cloned billing repository must contain composer.json." >&2; exit 1; }
composer install --no-interaction --prefer-dist --optimize-autoloader
npm install
if [[ -f frontend-next/package.json ]]; then npm --prefix frontend-next install; fi
if [[ ! " $* " == *" --skip-build "* ]]; then
    npm run build -- --configLoader runner
    if [[ -f frontend-next/package.json ]]; then
        npm --prefix frontend-next run typecheck
        npm --prefix frontend-next run build
    fi
fi

PHP_MM="$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;')"
install -d -m 0755 /etc/nginx/sites-available /etc/nginx/sites-enabled
install -d -m 0755 "${BILLING_DOCUMENT_ROOT}"
tee "${NGINX_SITE}" >/dev/null <<NGINX
server {
    listen 80;
    server_name ${SERVER_NAME:-_};
    root ${BILLING_DOCUMENT_ROOT};
    index index.php index.html;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_param HTTP_AUTHORIZATION \$http_authorization;
        fastcgi_param HTTP_X_FORWARDED_PROTO \$scheme;
        fastcgi_pass unix:/run/php/php${PHP_MM}-fpm.sock;
    }

    location ^~ /uploads/work-orders/ { deny all; }
    location ~ /\. { deny all; }
}
NGINX
ln -sfn "${NGINX_SITE}" "${NGINX_LINK}"
if [[ -e /etc/nginx/sites-enabled/default && ! -e /etc/nginx/sites-enabled/default.disabled ]]; then
    mv /etc/nginx/sites-enabled/default /etc/nginx/sites-enabled/default.disabled
fi
nginx -t
systemctl enable --now nginx
systemctl reload nginx
