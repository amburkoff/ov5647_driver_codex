#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=./lib.sh
source "${SCRIPT_DIR}/lib.sh"

STAMP=$(timestamp_utc)
LOGFILE="${LOG_DIR}/${STAMP}-run_smoke_tests.log"
MODULE_PATH=${1:-"${REPO_ROOT}/src/nv_ov5647/nv_ov5647.ko"}

{
    note "Starting smoke-test snapshot"
    note "Boot profile token: $(boot_profile_from_cmdline)"
} | tee "${LOGFILE}"

save_cmd_output "${LOG_DIR}/${STAMP}-smoke-uname.log" uname -a
save_cmd_output "${LOG_DIR}/${STAMP}-smoke-cmdline.log" cat /proc/cmdline
save_cmd_output "${LOG_DIR}/${STAMP}-smoke-lsmod.log" lsmod
save_cmd_output "${LOG_DIR}/${STAMP}-smoke-video-nodes.log" bash -lc "ls -l /dev/media* /dev/video* 2>&1 || true"

if [[ -f "${MODULE_PATH}" ]]; then
    modinfo "${MODULE_PATH}" >"${LOG_DIR}/${STAMP}-smoke-modinfo.log"
else
    printf "module not found: %s\n" "${MODULE_PATH}" >"${LOG_DIR}/${STAMP}-smoke-modinfo.log"
fi

if [[ -r /boot/extlinux/extlinux.conf ]]; then
    cp -- /boot/extlinux/extlinux.conf "${ARTIFACT_DIR}/boot/${STAMP}.extlinux.conf"
fi

note "Smoke-test snapshot finished" | tee -a "${LOGFILE}"

