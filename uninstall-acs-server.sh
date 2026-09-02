#!/usr/bin/env bash
# Remove the ACS/GenieACS installation created by install-acs-server-setup.sh.

set -Eeuo pipefail
IFS=$'\n\t'

ASSUME_YES=0

usage() {
    cat <<'EOF'
Usage: uninstall-acs-server.sh [--yes]

  --yes   Do not ask for confirmation.
EOF
}

for arg in "$@"; do
    case "${arg}" in
        --yes) ASSUME_YES=1 ;;
        --help|-h) usage; exit 0 ;;
        *) printf 'Unknown option: %s\n' "${arg}" >&2; usage >&2; exit 2 ;;
    esac
done

[[ "${EUID}" -eq 0 ]] || { printf 'Run as root: sudo bash %s\n' "$0" >&2; exit 1; }
command -v apt-get >/dev/null 2>&1 || { printf 'This script requires Ubuntu with apt-get.\n' >&2; exit 1; }

if [[ "${ASSUME_YES}" -ne 1 ]]; then
    printf 'This will remove GenieACS, MongoDB, ACS data, and related service files. Continue? [y/N] '
    read -r answer
    [[ "${answer}" =~ ^[Yy]$ ]] || { printf 'Cancelled.\n'; exit 0; }
fi

printf '[1WAN] Stopping ACS services...\n'
for service in cwmp nbi fs ui; do
    systemctl disable --now "genieacs-${service}.service" 2>/dev/null || true
done
systemctl disable --now mongod.service 2>/dev/null || true
systemctl daemon-reload 2>/dev/null || true

printf '[1WAN] Removing GenieACS package and files...\n'
if command -v npm >/dev/null 2>&1; then
    npm uninstall -g genieacs 2>/dev/null || true
fi
rm -f /etc/systemd/system/genieacs-cwmp.service \
      /etc/systemd/system/genieacs-nbi.service \
      /etc/systemd/system/genieacs-fs.service \
      /etc/systemd/system/genieacs-ui.service \
      /etc/logrotate.d/genieacs
rm -rf -- /opt/genieacs /var/log/genieacs
userdel genieacs 2>/dev/null || true

printf '[1WAN] Removing MongoDB packages and repository...\n'
apt-get purge -y mongodb-org mongodb-org-database mongodb-org-server mongodb-org-mongos mongodb-org-shell mongodb-org-tools mongodb-mongosh 2>/dev/null || true
apt-get autoremove -y
rm -f /etc/apt/sources.list.d/mongodb-org-4.4.list
rm -f /etc/apt/sources.list.d/mongodb-org.list
apt-get update

rm -f -- ./install-acs-server-setup.sh ./libssl1.1_1.1.0g-2ubuntu4_amd64.deb

printf '[1WAN] ACS/GenieACS installation artifacts have been removed.\n'
printf 'Node.js, npm, and libssl1.1 were preserved because other applications may use them.\n'

