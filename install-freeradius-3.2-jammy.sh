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
apt-get install -y ca-certificates curl

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

log "Installing FreeRADIUS 3.2 packages."
apt-get install -y freeradius freeradius-utils

if command -v systemctl >/dev/null 2>&1 && systemctl list-unit-files freeradius.service >/dev/null 2>&1; then
    log "Enabling and restarting the FreeRADIUS service."
    systemctl enable freeradius
    systemctl restart freeradius
    systemctl --no-pager --full status freeradius || true
else
    log "FreeRADIUS was installed. Start it with: systemctl enable --now freeradius"
fi

log "Installation completed. Existing /etc/freeradius configuration was preserved."

