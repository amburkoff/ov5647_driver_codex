#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=./lib.sh
source "${SCRIPT_DIR}/lib.sh"

STAMP=$(timestamp_utc)
LOGFILE="${LOG_DIR}/${STAMP}-run_argus_tests.log"

{
    note "Argus checks are not part of the current milestone gate"
    note "This script only records environment availability at this stage"
} | tee "${LOGFILE}"

if command -v gst-inspect-1.0 >/dev/null 2>&1; then
    gst-inspect-1.0 nvarguscamerasrc >"${LOG_DIR}/${STAMP}-gst-inspect-nvarguscamerasrc.log" 2>&1 || true
else
    printf "gst-inspect-1.0 is not installed\n" >"${LOG_DIR}/${STAMP}-gst-inspect-nvarguscamerasrc.log"
fi

note "Argus check finished" | tee -a "${LOGFILE}"

