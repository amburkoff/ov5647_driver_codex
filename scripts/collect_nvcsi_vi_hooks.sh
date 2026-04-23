#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=./lib.sh
source "${SCRIPT_DIR}/lib.sh"

STAMP=$(timestamp_utc)
OUT_DIR="${ARTIFACT_DIR}/nvcsi-vi-hooks/${STAMP}"
LOGFILE="${LOG_DIR}/${STAMP}-collect_nvcsi_vi_hooks.log"
TRACE_SCRIPT="${REPO_ROOT}/scripts/run_manual_single_frame_rtcpu_trace.sh"
OOT_TREE="${REPO_ROOT}/tools/vendor/linux-nv-oot-r36.5"
CAMRTC_TRACE_H="/usr/src/nvidia/nvidia-oot/include/soc/tegra/camrtc-trace.h"
RTCPU_DEBUG_C="${OOT_TREE}/drivers/platform/tegra/rtcpu/rtcpu-debug.c"
RTCPU_TRACE_C="${OOT_TREE}/drivers/platform/tegra/rtcpu/tegra-rtcpu-trace.c"
VI5_C="${OOT_TREE}/drivers/video/tegra/host/vi/vi5.c"
NVCSI_C="${OOT_TREE}/drivers/video/tegra/host/nvcsi/nvcsi.c"

mkdir -p "${OUT_DIR}"

{
	note "Collecting safe NVCSI/VI hook map"
	note "Boot profile token: $(boot_profile_from_cmdline)"
	note "Output dir: ${OUT_DIR}"
	note "No live debugfs regset files will be read"
} | tee "${LOGFILE}"

save_cmd_output "${OUT_DIR}/cmdline.log" cat /proc/cmdline
save_cmd_output "${OUT_DIR}/uname.log" uname -a
save_cmd_output "${OUT_DIR}/lsmod-camera.log" bash -lc "lsmod | grep -E 'nvhost_(nvcsi|vi5|capture)|tegra_camera|capture_ivc|ivc_bus|hsp_mailbox' || true"
save_cmd_output "${OUT_DIR}/module-paths.log" bash -lc "find /lib/modules/\$(uname -r) -type f \\( -name 'nvhost-nvcsi*.ko' -o -name 'nvhost-vi5.ko' -o -name 'nvhost-capture.ko' -o -name 'tegra-camera-rtcpu.ko' -o -name 'capture-ivc.ko' \\) | sort"

save_cmd_output "${OUT_DIR}/source-tree.log" bash -lc "
	printf 'OOT tree: %s\n' '${OOT_TREE}'
	if [[ -d '${OOT_TREE}/.git' ]]; then
		git -C '${OOT_TREE}' rev-parse --abbrev-ref HEAD
		git -C '${OOT_TREE}' rev-parse HEAD
	fi
	printf '\n'
	find '${OOT_TREE}/drivers' -maxdepth 5 \\( -path '*/camera/*' -o -path '*/nvcsi/*' -o -path '*/vi/*' -o -path '*/rtcpu/*' \\) | sort
"

save_cmd_output "${OUT_DIR}/camrtc-trace-ids.log" bash -lc "
	grep -nE 'camrtc_trace_vinotify_error|camrtc_trace_vi_frame_begin|camrtc_trace_vi_frame_end|camrtc_trace_nvcsi_intr|camrtc_trace_capture_event_sof|camrtc_trace_capture_event_eof|camrtc_trace_capture_event_error' '${CAMRTC_TRACE_H}'
"

save_cmd_output "${OUT_DIR}/rtcpu-trace-debugfs.log" bash -lc "
	grep -nE 'debugfs_create_(dir|file)|stats|last_exception|last_event' '${RTCPU_TRACE_C}'
"

save_cmd_output "${OUT_DIR}/rtcpu-debugfs-map.log" bash -lc "
	grep -nE 'debugfs_create_(dir|file|regset32)|coverage|version|reboot|ping|sm-ping|log-level|forced-reset-restore|irqstat|memstat|regs-common|regs-region' '${RTCPU_DEBUG_C}'
"

save_cmd_output "${OUT_DIR}/vi5-debugfs-map.log" bash -lc "
	grep -nE 'debugfs_create_regset32|vi5_init_debugfs|protocol_version|perforce_changelist|build_timestamp|channel_count' '${VI5_C}'
"

save_cmd_output "${OUT_DIR}/nvcsi-ioctl-map.log" bash -lc "
	grep -nE 'NVHOST_NVCSI_IOCTL_DESKEW_SETUP|NVHOST_NVCSI_IOCTL_DESKEW_APPLY|nvcsi_ioctl|deskew' '${NVCSI_C}'
"

save_cmd_output "${OUT_DIR}/manual-trace-events.log" bash -lc "
	awk '
		/^EVENTS=\\(/ { in_events=1; next }
		in_events && /^\\)/ { exit }
		in_events { print }
	' '${TRACE_SCRIPT}'
"

{
	note "Safe NVCSI/VI hook collection finished"
	note "Artifacts saved under ${OUT_DIR}"
} | tee -a "${LOGFILE}"
