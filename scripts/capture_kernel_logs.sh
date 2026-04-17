#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=./lib.sh
source "${SCRIPT_DIR}/lib.sh"

STAMP=$(timestamp_utc)
LOGFILE="${LOG_DIR}/${STAMP}-capture_kernel_logs.log"

{
    note "Capturing kernel logs"
    note "Boot profile token: $(boot_profile_from_cmdline)"
} | tee "${LOGFILE}"

save_cmd_output "${LOG_DIR}/${STAMP}-dmesg.log" bash -lc "dmesg 2>&1 || true"
save_cmd_output "${LOG_DIR}/${STAMP}-journalctl-k.log" bash -lc "journalctl -k 2>&1 || true"
save_cmd_output "${LOG_DIR}/${STAMP}-journalctl-k-b.log" bash -lc "journalctl -k -b 2>&1 || true"

{
    note "Kernel log capture finished"
    note "Saved dmesg and journalctl outputs into ${LOG_DIR}"
} | tee -a "${LOGFILE}"
