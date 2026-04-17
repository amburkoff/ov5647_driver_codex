#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "${SCRIPT_DIR}/.." && pwd)
LOG_DIR="${REPO_ROOT}/logs"
ARTIFACT_DIR="${REPO_ROOT}/artifacts"

mkdir -p "${LOG_DIR}" "${ARTIFACT_DIR}"

timestamp_utc() {
    date -u +"%Y%m%dT%H%M%SZ"
}

log_path() {
    local name=${1:?log name is required}
    printf "%s/%s-%s.log\n" "${LOG_DIR}" "$(timestamp_utc)" "${name}"
}

note() {
    printf "[%s] %s\n" "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" "$*"
}

require_cmd() {
    local cmd=${1:?command name is required}

    if ! command -v "${cmd}" >/dev/null 2>&1; then
        printf "missing required command: %s\n" "${cmd}" >&2
        exit 1
    fi
}

require_root() {
    if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
        printf "this script must run as root\n" >&2
        exit 1
    fi
}

boot_profile_from_cmdline() {
    local cmdline

    cmdline=$(cat /proc/cmdline)
    if [[ "${cmdline}" =~ boot_profile=([^[:space:]]+) ]]; then
        printf "%s\n" "${BASH_REMATCH[1]}"
    else
        printf "unset\n"
    fi
}

save_cmd_output() {
    local outfile=${1:?output file is required}
    shift

    {
        note "CMD: $*"
        "$@"
    } >"${outfile}" 2>&1
}

copy_if_readable() {
    local src=${1:?source path is required}
    local dst=${2:?destination path is required}

    if [[ -r "${src}" ]]; then
        cp -- "${src}" "${dst}"
    else
        printf "unreadable: %s\n" "${src}" >"${dst}"
    fi
}

