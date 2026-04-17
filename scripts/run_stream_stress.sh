#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=./lib.sh
source "${SCRIPT_DIR}/lib.sh"

DEVICE=${1:-/dev/video0}
COUNT=${2:-10}
STAMP=$(timestamp_utc)
LOGFILE="${LOG_DIR}/${STAMP}-run_stream_stress.log"

{
    note "Starting stream stress test"
    note "Device: ${DEVICE}"
    note "Iterations: ${COUNT}"
} | tee "${LOGFILE}"

if ! command -v v4l2-ctl >/dev/null 2>&1; then
    note "SKIP: v4l2-ctl is not installed" | tee -a "${LOGFILE}"
    exit 0
fi

if ! [[ -e "${DEVICE}" ]]; then
    note "SKIP: device does not exist: ${DEVICE}" | tee -a "${LOGFILE}"
    exit 0
fi

for ((i = 1; i <= COUNT; ++i)); do
    note "Iteration ${i}/${COUNT}" | tee -a "${LOGFILE}"
    v4l2-ctl --device "${DEVICE}" --stream-mmap=4 --stream-count=1 --stream-to=/dev/null >>"${LOGFILE}" 2>&1
done

note "Stream stress test finished" | tee -a "${LOGFILE}"

