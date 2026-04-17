#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=./lib.sh
source "${SCRIPT_DIR}/lib.sh"

DEVICE=${1:-/dev/video0}
STAMP=$(timestamp_utc)
LOGFILE="${LOG_DIR}/${STAMP}-run_v4l2_tests.log"

{
    note "Starting V4L2 test collection"
    note "Requested device: ${DEVICE}"
} | tee "${LOGFILE}"

if ! command -v v4l2-ctl >/dev/null 2>&1; then
    note "SKIP: v4l2-ctl is not installed" | tee -a "${LOGFILE}"
    exit 0
fi

if ! [[ -e "${DEVICE}" ]]; then
    note "SKIP: device does not exist: ${DEVICE}" | tee -a "${LOGFILE}"
    exit 0
fi

v4l2-ctl --list-devices >"${LOG_DIR}/${STAMP}-v4l2-list-devices.log" 2>&1 || true
v4l2-ctl --device "${DEVICE}" --all >"${LOG_DIR}/${STAMP}-v4l2-all.log" 2>&1 || true
v4l2-ctl --device "${DEVICE}" --list-formats-ext >"${LOG_DIR}/${STAMP}-v4l2-formats.log" 2>&1 || true

if command -v media-ctl >/dev/null 2>&1; then
    media-ctl -p >"${LOG_DIR}/${STAMP}-media-ctl-p.log" 2>&1 || true
else
    printf "media-ctl is not installed\n" >"${LOG_DIR}/${STAMP}-media-ctl-p.log"
fi

if command -v v4l2-compliance >/dev/null 2>&1; then
    v4l2-compliance -d "${DEVICE}" >"${LOG_DIR}/${STAMP}-v4l2-compliance.log" 2>&1 || true
else
    printf "v4l2-compliance is not installed\n" >"${LOG_DIR}/${STAMP}-v4l2-compliance.log"
fi

note "V4L2 test collection finished" | tee -a "${LOGFILE}"

