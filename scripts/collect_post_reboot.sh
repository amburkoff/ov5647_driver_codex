#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=./lib.sh
source "${SCRIPT_DIR}/lib.sh"

STAMP=$(timestamp_utc)
POST_DIR="${ARTIFACT_DIR}/post-reboot/${STAMP}"
LOGFILE="${LOG_DIR}/${STAMP}-collect_post_reboot.log"

mkdir -p "${POST_DIR}"

{
    note "Collecting post-reboot state"
    note "Boot profile token: $(boot_profile_from_cmdline)"
} | tee "${LOGFILE}"

save_cmd_output "${POST_DIR}/cmdline.log" cat /proc/cmdline
save_cmd_output "${POST_DIR}/uname.log" uname -a
save_cmd_output "${POST_DIR}/lsmod.log" lsmod
save_cmd_output "${POST_DIR}/video-nodes.log" bash -lc "ls -l /dev/media* /dev/video* 2>&1 || true"
save_cmd_output "${POST_DIR}/dmesg.log" bash -lc "dmesg 2>&1 || true"
save_cmd_output "${POST_DIR}/journalctl-k-b.log" bash -lc "journalctl -k -b 2>&1 || true"
save_cmd_output "${POST_DIR}/pstore-ls.log" bash -lc "ls -la /sys/fs/pstore 2>&1 || true"
save_cmd_output "${POST_DIR}/pstore-find.log" bash -lc "find /sys/fs/pstore -maxdepth 1 -type f 2>&1 || true"

note "Post-reboot collection finished; artifacts saved under ${POST_DIR}" | tee -a "${LOGFILE}"
