#!/usr/bin/env bash
set -Eeuo pipefail

readonly SCRIPT_URL="https://raw.githubusercontent.com/kevindb23/install-isp-box/main/install-acs-server-setup.sh"
readonly SCRIPT_FILE="install-acs-server-setup.sh"

if [[ "${EUID}" -ne 0 ]]; then
    printf 'Run as root: sudo bash %s\n' "$0" >&2
    exit 1
fi

printf '[1WAN] Installing prerequisites...\n'
apt-get update -y
apt-get install -y dos2unix wget

printf '[1WAN] Downloading ACS server setup...\n'
wget -qO "${SCRIPT_FILE}" "${SCRIPT_URL}"
dos2unix "${SCRIPT_FILE}"
chmod +x "${SCRIPT_FILE}"

printf '[1WAN] Running ACS server setup...\n'
exec "./${SCRIPT_FILE}"
