#!/usr/bin/env bash
# Uninstall Accel-PPP installed by install-accel-ppp.sh.

set -Eeuo pipefail
IFS=$'\n\t'

readonly SOURCE_DIR="${ACCEL_SOURCE_DIR:-/opt/accel-ppp-code}"
readonly FRR_KEYRING="/usr/share/keyrings/frrouting.gpg"
readonly FRR_SOURCE="/etc/apt/sources.list.d/frr.list"
PURGE_CONFIG=0
ASSUME_YES=0

usage() {
    cat <<'EOF'
Usage: uninstall-accel-ppp.sh [--yes] [--purge-config]

  --yes            Do not ask for confirmation.
  --purge-config   Also remove /etc/accel-ppp.conf and /etc/frr.
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
    systemctl disable --now frr 2>/dev/null || true
fi

apt-get purge -y accel-ppp frr frr-pythontools 2>/dev/null || true
apt-get autoremove -y

rm -f /etc/apt/sources.list.d/inkbridge.list
rm -f "${FRR_SOURCE}" "${FRR_KEYRING}"
rm -f /etc/apt/preferences.d/networkradius
rm -f /etc/apt/keyrings/packages.networkradius.com.asc
apt-get update

sed -i -e "/net.ipv4.ip_forward=1/d" -e "/net.ipv6.conf.all.forwarding=1/d" /etc/sysctl.conf
sysctl -p >/dev/null 2>&1 || true

if [[ "${PURGE_CONFIG}" -eq 1 ]]; then
    rm -f /etc/accel-ppp.conf /etc/accel-ppp.conf.dist
    rm -rf -- /etc/frr /var/log/frr
else
    printf 'Preserved /etc/accel-ppp.conf. Use --purge-config to remove it.\n'
fi

if [[ -d "${SOURCE_DIR}" ]]; then
    rm -rf -- "${SOURCE_DIR}"
fi

printf 'Accel-PPP and installer-created files have been removed.\n'

