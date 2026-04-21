#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=./lib.sh
source "${SCRIPT_DIR}/lib.sh"

require_root
require_cmd rmmod

STAMP=$(timestamp_utc)
LOGFILE="${LOG_DIR}/${STAMP}-unload_module.log"

{
    note "Removing nv_ov5647"
    note "Boot profile token: $(boot_profile_from_cmdline)"
} | tee "${LOGFILE}"

if ! lsmod | awk '$1 == "nv_ov5647" { found = 1 } END { exit(found ? 0 : 1) }'; then
    note "nv_ov5647 is not loaded" | tee -a "${LOGFILE}"
    exit 0
fi

if [[ "${OV5647_ALLOW_UNSAFE_RMMOD:-0}" != "1" ]]; then
    {
        note "Refusing direct rmmod because full V4L2 unload can hard-hang this Jetson"
        note "Use scripts/run_manual_rmmod_trace.sh manually, or set OV5647_ALLOW_UNSAFE_RMMOD=1 only for a controlled diagnostic run"
    } | tee -a "${LOGFILE}"
    exit 2
fi

note "OV5647_ALLOW_UNSAFE_RMMOD=1 set; running direct rmmod" | tee -a "${LOGFILE}"
rmmod nv_ov5647 2>&1 | tee -a "${LOGFILE}"
dmesg | tail -n 80 >"${LOG_DIR}/${STAMP}-unload_module.dmesg-tail.log"

note "Module unload finished" | tee -a "${LOGFILE}"
