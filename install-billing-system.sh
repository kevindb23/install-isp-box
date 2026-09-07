#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

REPOSITORY_URL="${REPOSITORY_URL:-https://github.com/kevindb23/ISP-Box.git}"
APP_DIR="${APP_DIR:-/var/www/billing-server}"
DOCUMENT_ROOT="${DOCUMENT_ROOT:-${APP_DIR}/public}"
BRANCH="${BRANCH:-main}"
NGINX_SITE="/etc/nginx/sites-available/billing-server"
NGINX_LINK="/etc/nginx/sites-enabled/billing-server"
WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT

[[ "$EUID" -eq 0 ]] || {
    echo "Run this script as root."
    exit 1
}

apt-get update
apt-get install -y \
    ca-certificates curl git unzip nginx mysql-server \
    php-cli php-fpm php-common php-mysql php-curl php-mbstring \
    php-xml php-zip python3 composer nodejs npm

read -r -p "MySQL database name [portal]: " DB_NAME
read -r -p "MySQL username [portal_radius]: " DB_USER
read -r -s -p "MySQL password: " DB_PASSWORD
printf '\n'

read -r -p "Web UI administrator username: " ADMIN_USERNAME
read -r -s -p "Web UI administrator password: " ADMIN_PASSWORD
printf '\n'

DB_NAME="${DB_NAME:-portal}"
DB_USER="${DB_USER:-portal_radius}"

[[ "$DB_NAME" =~ ^[A-Za-z0-9_]+$ ]] || {
    echo "Invalid database name."
    exit 1
}

[[ "$DB_USER" =~ ^[A-Za-z0-9_]+$ ]] || {
    echo "Invalid database username."
    exit 1
}

install -d -m 0755 "$(dirname "$APP_DIR")"

if [[ -d "$APP_DIR/.git" ]]; then
    git -C "$APP_DIR" fetch --prune origin
    git -C "$APP_DIR" checkout "$BRANCH"
    git -C "$APP_DIR" reset --hard "origin/$BRANCH"
else
    rm -rf "$APP_DIR"
    git clone --branch "$BRANCH" --single-branch "$REPOSITORY_URL" "$APP_DIR"
fi

cd "$APP_DIR"

DB_PASSWORD_SQL="${DB_PASSWORD//\\/\\\\}"
DB_PASSWORD_SQL="${DB_PASSWORD_SQL//\'/\'\'}"

mysql --protocol=socket -uroot <<SQL
CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\`
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost'
    IDENTIFIED BY '${DB_PASSWORD_SQL}';

CREATE USER IF NOT EXISTS '${DB_USER}'@'127.0.0.1'
    IDENTIFIED BY '${DB_PASSWORD_SQL}';

ALTER USER '${DB_USER}'@'localhost'
    IDENTIFIED BY '${DB_PASSWORD_SQL}';

ALTER USER '${DB_USER}'@'127.0.0.1'
    IDENTIFIED BY '${DB_PASSWORD_SQL}';

GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${DB_USER}'@'localhost';
GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${DB_USER}'@'127.0.0.1';

FLUSH PRIVILEGES;
SQL

if [[ -f "$APP_DIR/billing.sql" ]]; then
    mysql --protocol=socket -uroot "$DB_NAME" < "$APP_DIR/billing.sql"
fi

ADMIN_USERNAME_SQL="${ADMIN_USERNAME//\'/\'\'}"
ADMIN_PASSWORD_HASH="$(php -r 'echo password_hash($argv[1], PASSWORD_DEFAULT);' "$ADMIN_PASSWORD")"

mysql --protocol=socket -uroot "$DB_NAME" <<SQL
DELETE FROM users
WHERE role = 'SUPERADMIN';

DELETE FROM login_attempts
WHERE username = '${ADMIN_USERNAME_SQL}';

INSERT INTO users
    (username, full_name, email, password, role, status)
VALUES
    (
        '${ADMIN_USERNAME_SQL}',
        'System Administrator',
        '${ADMIN_USERNAME_SQL}@localhost',
        '${ADMIN_PASSWORD_HASH}',
        'SUPERADMIN',
        'ACTIVE'
    );
SQL

STORED_HASH="$(
    mysql --protocol=socket -uroot "$DB_NAME" \
        --batch --skip-column-names \
        -e "SELECT password FROM users WHERE username='${ADMIN_USERNAME_SQL}' AND role='SUPERADMIN' AND status='ACTIVE' LIMIT 1;"
)"

php -r '
if (!password_verify($argv[1], $argv[2])) {
    exit(1);
}
' "$ADMIN_PASSWORD" "$STORED_HASH" || {
    echo "Administrator password verification failed."
    exit 1
}

cat > "$APP_DIR/.env.runtime.php" <<PHP_RUNTIME
<?php

return [
    'portal_db' => [
        'host' => '127.0.0.1',
        'user' => '${DB_USER}',
        'pass' => '${DB_PASSWORD}',
        'name' => '${DB_NAME}',
    ],
    'coa' => [
        'host' => '${COA_HOST:-127.0.0.1}',
        'port' => ${COA_PORT:-3799},
        'secret' => '${COA_SECRET:-CHANGE_ME}',
        'radclient_path' => '/usr/bin/radclient',
    ],
];
PHP_RUNTIME

chmod 0640 "$APP_DIR/.env.runtime.php"
chown root:www-data "$APP_DIR/.env.runtime.php"

composer install --no-interaction --prefer-dist --optimize-autoloader
npm install
npm run build

if [[ -f "$APP_DIR/frontend-next/package.json" ]]; then
    npm --prefix frontend-next install
    npm --prefix frontend-next run build
fi

chown -R root:root "$APP_DIR"
chmod 0640 "$APP_DIR/.env.runtime.php"
chown root:www-data "$APP_DIR/.env.runtime.php"

PHP_VERSION="$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;')"

cat > "$NGINX_SITE" <<NGINX
server {
    listen 80 default_server;
    server_name _;

    root ${DOCUMENT_ROOT};
    index index.php index.html;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location /build/ {
        try_files \$uri =404;
    }

    location /build-next/ {
        try_files \$uri =404;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_param HTTP_AUTHORIZATION \$http_authorization;
        fastcgi_param HTTP_X_FORWARDED_PROTO \$scheme;
        fastcgi_pass unix:/run/php/php${PHP_VERSION}-fpm.sock;
    }

    location ~ /\. {
        deny all;
    }
}
NGINX

ln -sfn "$NGINX_SITE" "$NGINX_LINK"
rm -f /etc/nginx/sites-enabled/default

nginx -t
systemctl enable --now mysql
systemctl enable --now "php${PHP_VERSION}-fpm"
systemctl enable --now nginx
systemctl reload nginx

echo
echo "Installation completed successfully."
echo "Login username: ${ADMIN_USERNAME}"
echo "Application directory: ${APP_DIR}"
