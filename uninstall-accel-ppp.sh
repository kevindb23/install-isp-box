#!/usr/bin/env bash
# Uninstall Accel-PPP installed by install-accel-ppp.sh.

set -Eeuo pipefail
IFS=$'\n\t'

readonly SOURCE_DIR="${ACCEL_SOURCE_DIR:-/opt/accel-ppp-code}"
PURGE_CONFIG=0
ASSUME_YES=0

usage() {
    cat <<'EOF'
Usage: uninstall-accel-ppp.sh [--yes] [--purge-config]

  --yes            Do not ask for confirmation.
  --purge-config   Also remove /etc/accel-ppp.conf.
EOF
}

for arg in "$@"; do
    case "${arg}" in
        --yes) ASSUME_YES=1 ;;
        --purge-config) PURGE_CONFIG=1 ;;
        --help|-h) usage; exit 0 ;;
        *) printf 'Unknown option: %s\n' "${arg}" >&2; usage >&2; exit 2 ;;
    esac
done

[[ "${EUID}" -eq 0 ]] || { printf 'Run as root: sudo bash %s\n' "$0" >&2; exit 1; }
command -v apt-get >/dev/null 2>&1 || { printf 'This script requires Ubuntu with apt-get.\n' >&2; exit 1; }

if [[ "${ASSUME_YES}" -ne 1 ]]; then
    printf 'This will remove Accel-PPP, its repository files, and %s. Continue? [y/N] ' "${SOURCE_DIR}"
    read -r answer
    [[ "${answer}" =~ ^[Yy]$ ]] || { printf 'Cancelled.\n'; exit 0; }
fi

if command -v systemctl >/dev/null 2>&1; then
    systemctl disable --now accel-ppp 2>/dev/null || true
fi

apt-get purge -y accel-ppp 2>/dev/null || true
apt-get autoremove -y

rm -f /etc/apt/sources.list.d/inkbridge.list
rm -f /etc/apt/preferences.d/networkradius
rm -f /etc/apt/keyrings/packages.networkradius.com.asc
apt-get update

if [[ "${PURGE_CONFIG}" -eq 1 ]]; then
    rm -f /etc/accel-ppp.conf /etc/accel-ppp.conf.dist
else
    printf 'Preserved /etc/accel-ppp.conf. Use --purge-config to remove it.\n'
fi

if [[ -d "${SOURCE_DIR}" ]]; then
    rm -rf -- "${SOURCE_DIR}"
fi

printf 'Accel-PPP and installer-created files have been removed.\n'

