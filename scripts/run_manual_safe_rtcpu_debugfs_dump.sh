#!/usr/bin/env bash
set -euo pipefail
shopt -s nullglob

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TS="$(date -u +%Y%m%dT%H%M%SZ)"
LOG_DIR="${ROOT_DIR}/logs"
OUT_DIR="${ROOT_DIR}/artifacts/rtcpu-debugfs/${TS}"
RUN_LOG="${LOG_DIR}/${TS}-safe-rtcpu-debugfs-dump.log"
TRACE_DIR="/sys/kernel/debug/tegra_rtcpu_trace"

if [[ ${EUID} -ne 0 ]]; then
	echo "run as root: sudo $0" >&2
	exit 1
fi

mkdir -p "${LOG_DIR}" "${OUT_DIR}"

log() {
	echo "[${TS}] $*" | tee -a "${RUN_LOG}"
}

copy_file() {
	local src="$1"
	local dst="$2"

	if [[ -r "${src}" ]]; then
		cat "${src}" > "${dst}" 2>&1 || true
	else
		echo "missing or unreadable: ${src}" > "${dst}"
	fi
}

fix_permissions() {
	chmod -R a+rX "${OUT_DIR}" 2>/dev/null || true
	chmod a+r "${RUN_LOG}" 2>/dev/null || true
	if [[ -n "${SUDO_UID:-}" && -n "${SUDO_GID:-}" ]]; then
		chown -R "${SUDO_UID}:${SUDO_GID}" "${OUT_DIR}" 2>/dev/null || true
		chown "${SUDO_UID}:${SUDO_GID}" "${RUN_LOG}" 2>/dev/null || true
	fi
}

trap fix_permissions EXIT

log "starting safe RTCPU debugfs dump"
log "trace dir=${TRACE_DIR}"
log "output dir=${OUT_DIR}"
log "restricted to tegra_rtcpu_trace/{stats,last_exception,last_event}"
log "does not read VI/camrtc regset32 nodes"

{
	echo "# cmdline"
	cat /proc/cmdline
	echo
	echo "# debugfs mount"
	mount | grep debugfs || true
	echo
	echo "# lsmod camera-related"
	lsmod | grep -E 'nvhost_(nvcsi|vi5|capture)|tegra_camera|capture_ivc|ivc_bus|hsp_mailbox' || true
	echo
	echo "# trace dir listing"
	ls -la "${TRACE_DIR}" 2>&1 || true
} > "${OUT_DIR}/pre-state.log" 2>&1

copy_file "${TRACE_DIR}/stats" "${OUT_DIR}/stats.log"
copy_file "${TRACE_DIR}/last_exception" "${OUT_DIR}/last_exception.log"
copy_file "${TRACE_DIR}/last_event" "${OUT_DIR}/last_event.log"

log "saved ${OUT_DIR}/stats.log"
log "saved ${OUT_DIR}/last_exception.log"
log "saved ${OUT_DIR}/last_event.log"
