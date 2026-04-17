#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=./lib.sh
source "${SCRIPT_DIR}/lib.sh"

require_root
require_cmd insmod
require_cmd modinfo

MODULE_PATH=${1:-"${REPO_ROOT}/src/nv_ov5647/nv_ov5647.ko"}
STAMP=$(timestamp_utc)
LOGFILE="${LOG_DIR}/${STAMP}-install_module.log"

{
    note "Installing module: ${MODULE_PATH}"
    note "Boot profile token: $(boot_profile_from_cmdline)"
} | tee "${LOGFILE}"

if ! [[ -f "${MODULE_PATH}" ]]; then
    printf "module not found: %s\n" "${MODULE_PATH}" >&2
    exit 1
fi

if lsmod | awk '$1 == "nv_ov5647" { found = 1 } END { exit(found ? 0 : 1) }'; then
    note "nv_ov5647 is already loaded" | tee -a "${LOGFILE}"
    exit 0
fi

modinfo "${MODULE_PATH}" >"${LOG_DIR}/${STAMP}-install_module.modinfo.log"
insmod "${MODULE_PATH}" 2>&1 | tee -a "${LOGFILE}"
dmesg | tail -n 80 >"${LOG_DIR}/${STAMP}-install_module.dmesg-tail.log"

note "Module install finished" | tee -a "${LOGFILE}"

