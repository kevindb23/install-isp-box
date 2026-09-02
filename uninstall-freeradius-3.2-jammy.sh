#!/usr/bin/env bash
# Uninstall FreeRADIUS installed by install-freeradius-3.2-jammy.sh.

set -Eeuo pipefail
IFS=$'\n\t'

PURGE_CONFIG=0
ASSUME_YES=0

usage() {
    cat <<'EOF'
Usage: uninstall-freeradius-3.2-jammy.sh [--yes] [--purge-config]

  --yes            Do not ask for confirmation.
  --purge-config   Also purge /etc/freeradius and FreeRADIUS logs.
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
    printf 'This will remove FreeRADIUS and its InkBridge APT files. Continue? [y/N] '
    read -r answer
    [[ "${answer}" =~ ^[Yy]$ ]] || { printf 'Cancelled.\n'; exit 0; }
fi

if command -v systemctl >/dev/null 2>&1; then
    systemctl disable --now freeradius 2>/dev/null || true
fi

if [[ "${PURGE_CONFIG}" -eq 1 ]]; then
    apt-get purge -y freeradius freeradius-utils
else
    apt-get remove -y freeradius freeradius-utils
    printf 'Preserved /etc/freeradius. Use --purge-config to remove configuration and logs.\n'
fi
apt-get autoremove -y

rm -f /etc/apt/sources.list.d/inkbridge.list
rm -f /etc/apt/preferences.d/networkradius
rm -f /etc/apt/keyrings/packages.networkradius.com.asc
apt-get update

if [[ "${PURGE_CONFIG}" -eq 1 ]]; then
    rm -rf -- /etc/freeradius /var/log/freeradius
fi

printf 'FreeRADIUS and installer-created repository files have been removed.\n'

