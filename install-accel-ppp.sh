#!/usr/bin/env bash
# Install Accel-PPP on Ubuntu from the upstream master branch.
# Based on: https://docs.accel-ppp.org/installation/ubuntu.html

set -Eeuo pipefail
IFS=$'\n\t'

readonly SOURCE_DIR="${ACCEL_SOURCE_DIR:-/opt/accel-ppp-code}"
readonly BUILD_DIR="${SOURCE_DIR}/build"
readonly REPOSITORY="${ACCEL_REPOSITORY:-https://github.com/accel-ppp/accel-ppp.git}"
readonly INSTALL_PREFIX="${ACCEL_INSTALL_PREFIX:-/usr}"

log() {
    printf '[accel-ppp] %s\n' "$*"
}

die() {
    printf '[accel-ppp] ERROR: %s\n' "$*" >&2
    exit 1
}

trap 'die "Installation failed near line ${LINENO}."' ERR

[[ "${EUID}" -eq 0 ]] || die "Run this script as root, for example: sudo bash $0"

command -v apt-get >/dev/null 2>&1 || die "This installer requires Ubuntu with apt-get."
[[ -r /etc/os-release ]] || die "Cannot identify the operating system."
# shellcheck disable=SC1091
source /etc/os-release
[[ "${ID:-}" == "ubuntu" ]] || die "This installer supports Ubuntu only. Detected: ${ID:-unknown}."

ubuntu_major="${VERSION_ID%%.*}"
[[ "${ubuntu_major}" =~ ^[0-9]+$ ]] || die "Cannot determine Ubuntu version from VERSION_ID=${VERSION_ID:-unknown}."
readonly CPACK_TYPE="${ACCEL_CPACK_TYPE:-Ubuntu${ubuntu_major}}"

export DEBIAN_FRONTEND=noninteractive

log "Installing build dependencies."
apt-get update
apt-get install -y \
    build-essential \
    cmake \
    gcc \
    "linux-headers-$(uname -r)" \
    git \
    libpcre2-dev \
    libssl-dev \
    liblua5.1-0-dev

if [[ -d "${SOURCE_DIR}/.git" ]]; then
    log "Updating existing source tree at ${SOURCE_DIR}."
    git -C "${SOURCE_DIR}" fetch --prune origin
    git -C "${SOURCE_DIR}" pull --ff-only origin master
elif [[ -e "${SOURCE_DIR}" ]]; then
    die "${SOURCE_DIR} exists but is not an Accel-PPP Git checkout."
else
    log "Cloning Accel-PPP into ${SOURCE_DIR}."
    git clone "${REPOSITORY}" "${SOURCE_DIR}"
fi

mkdir -p "${BUILD_DIR}"
cd "${BUILD_DIR}"

log "Configuring Accel-PPP with CPack target ${CPACK_TYPE}."
cmake \
    -DBUILD_IPOE_DRIVER=TRUE \
    -DBUILD_VLAN_MON_DRIVER=TRUE \
    -DCMAKE_INSTALL_PREFIX="${INSTALL_PREFIX}" \
    -DKDIR="/usr/src/linux-headers-$(uname -r)" \
    -DLUA=TRUE \
    -DCPACK_TYPE="${CPACK_TYPE}" \
    ..

log "Compiling Accel-PPP."
make -j"$(nproc)"

log "Creating the Debian package."
cpack -G DEB

deb_package="$(find . -maxdepth 1 -type f -name '*.deb' -printf '%T@ %p\n' | sort -nr | head -n 1 | cut -d' ' -f2-)"
[[ -n "${deb_package}" && -f "${deb_package}" ]] || die "CMake completed but no Debian package was produced."

log "Installing ${deb_package}."
dpkg -i "${deb_package}" || apt-get install -f -y

if [[ ! -e /etc/accel-ppp.conf ]]; then
    [[ -e /etc/accel-ppp.conf.dist ]] || die "Installed package did not provide /etc/accel-ppp.conf.dist."
    log "Creating /etc/accel-ppp.conf from the distributed sample."
    mv /etc/accel-ppp.conf.dist /etc/accel-ppp.conf
else
    log "Keeping existing /etc/accel-ppp.conf."
fi

if command -v systemctl >/dev/null 2>&1; then
    log "Enabling and starting the accel-ppp systemd service."
    systemctl daemon-reload
    systemctl enable accel-ppp
    systemctl restart accel-ppp
    systemctl --no-pager --full status accel-ppp || true
else
    log "systemctl is unavailable; start manually with:"
    log "accel-pppd -d -c /etc/accel-ppp.conf -p /var/run/accel-ppp.pid"
fi

log "Installation completed. Review /etc/accel-ppp.conf before production use."

