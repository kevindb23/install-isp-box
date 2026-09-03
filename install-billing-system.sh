#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

readonly SCRIPT_URL="${SCRIPT_URL:-https://raw.githubusercontent.com/kevindb23/install-isp-box/main/install-billing-server.sh}"
readonly DEFAULT_REPOSITORY_URL="${REPOSITORY_URL:-https://github.com/kevindb23/ISP-Box.git}"
readonly WORK_DIR="$(mktemp -d -t billing-system.XXXXXX)"
trap 'rm -rf "${WORK_DIR}"' EXIT

usage() {
    cat <<'EOF'
Usage: sudo bash install-billing-system.sh [--skip-build|--setup-database]

Bootstrap installer for the ISP-Box billing system.
Environment:
  REPOSITORY_URL  Application Git URL; default: https://github.com/kevindb23/ISP-Box.git
  SCRIPT_URL      Installer URL; normally leave unchanged.
  APP_DIR         Install directory; default: /var/www/billing
  SERVER_NAME     Nginx server_name; default: _
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
    apt-get install -y ca-certificates curl
    bash_cmd=(bash)
else
    sudo apt-get update -y
    sudo apt-get install -y ca-certificates curl
    bash_cmd=(sudo bash)
fi

curl --fail --silent --show-error --location "${SCRIPT_URL}" -o "${WORK_DIR}/install-billing-server.sh"
chmod 700 "${WORK_DIR}/install-billing-server.sh"
REPOSITORY_URL="${DEFAULT_REPOSITORY_URL}" "${bash_cmd[@]}" "${WORK_DIR}/install-billing-server.sh" "$@"
