#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

readonly APP_DIR="${APP_DIR:-/var/www/billing-server}"
readonly BRANCH="${BRANCH:-main}"
readonly SERVER_NAME="${SERVER_NAME:-_}"
readonly NGINX_SITE="/etc/nginx/sites-available/billing-server"
readonly NGINX_LINK="/etc/nginx/sites-enabled/billing-server"
readonly BILLING_SQL_FILE="${BILLING_SQL_FILE:-}"

SKIP_BUILD=0
SETUP_DATABASE=0

usage() {
    cat <<'EOF'
Usage: sudo REPOSITORY_URL=https://github.com/owner/app.git bash install-billing-server.sh [options]

Options:
  --skip-build       Install dependencies but do not build frontends.
  --setup-database   Create the database/user from DB_NAME, DB_USER, DB_PASSWORD.
  -h, --help         Show this help.

Environment:
  REPOSITORY_URL     Required Git repository URL.
  BRANCH             Git branch; default: main.
  APP_DIR            Install directory; default: /var/www/billing-server.
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

REPOSITORY_URL="${REPOSITORY_URL:-https://github.com/kevindb23/ISP-Box.git}"
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

if [[ -d "${APP_DIR}/.git" ]]; then
    CURRENT_REMOTE="$(git -C "${APP_DIR}" remote get-url origin 2>/dev/null || true)"
    [[ -n "${CURRENT_REMOTE}" ]] || fail "Existing checkout has no origin remote: ${APP_DIR}."
    git -C "${APP_DIR}" fetch --prune origin
    git -C "${APP_DIR}" checkout "${BRANCH}"
    git -C "${APP_DIR}" pull --ff-only origin "${BRANCH}"
elif [[ -e "${APP_DIR}" ]]; then
    fail "${APP_DIR} exists but is not a Git checkout."
else
    run_root install -d -m 0755 "$(dirname "${APP_DIR}")"
    git clone --branch "${BRANCH}" --single-branch "${REPOSITORY_URL}" "${APP_DIR}"
fi

chown -R root:root "${APP_DIR}"
cd "${APP_DIR}"
composer install --no-interaction --prefer-dist --optimize-autoloader
npm install
if [[ -f frontend-next/package.json ]]; then npm --prefix frontend-next install; fi

if (( SKIP_BUILD == 0 )); then
    npm run build -- --configLoader runner
    if [[ -f frontend-next/package.json ]]; then
        npm --prefix frontend-next run typecheck
        npm --prefix frontend-next run build
    fi
fi

if (( SETUP_DATABASE == 1 )); then
    DB_NAME="${DB_NAME:-portal}"
    DB_USER="${DB_USER:-billing}"
    DB_PASSWORD="${DB_PASSWORD:-N3t3ng777}"
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
fi

run_root install -d -m 0755 /etc/nginx/sites-available /etc/nginx/sites-enabled
run_root tee "${NGINX_SITE}" >/dev/null <<NGINX
server {
    listen 80;
    server_name ${SERVER_NAME};
    root ${APP_DIR}/public;
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
run_root ln -sfn "${NGINX_SITE}" "${NGINX_LINK}"
if [[ -e /etc/nginx/sites-enabled/default && ! -e /etc/nginx/sites-enabled/default.disabled ]]; then
    run_root mv /etc/nginx/sites-enabled/default /etc/nginx/sites-enabled/default.disabled
fi
run_root nginx -t
run_root systemctl enable --now mysql nginx "php${PHP_MM}-fpm"
run_root systemctl reload nginx

printf '[billing-server] Installation completed. Application: %s\n' "${APP_DIR}"
printf '[billing-server] Web root: %s/public\n' "${APP_DIR}"
