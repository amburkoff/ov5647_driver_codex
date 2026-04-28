#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TS="$(date -u +%Y%m%dT%H%M%SZ)"
LOG_DIR="${ROOT_DIR}/logs"
CAP_DIR="${ROOT_DIR}/artifacts/captures/${TS}"
LOGFILE="${LOG_DIR}/${TS}-manual-v4l2-direct-stream.log"
DMESG_LOG="${LOG_DIR}/${TS}-manual-v4l2-direct-stream-live-dmesg.log"
POST_DMESG_LOG="${LOG_DIR}/${TS}-manual-v4l2-direct-stream-post-dmesg-tail.log"

DEVICE="${DEVICE:-/dev/video0}"
WIDTH="${WIDTH:-640}"
HEIGHT="${HEIGHT:-480}"
PIXELFORMAT="${PIXELFORMAT:-BG10}"
SENSOR_MODE="${SENSOR_MODE:-0}"
STREAM_COUNT="${STREAM_COUNT:-100}"
CAPTURE_TIMEOUT_SEC="${CAPTURE_TIMEOUT_SEC:-30}"
OUT_FILE="${CAP_DIR}/ov5647-${WIDTH}x${HEIGHT}-${PIXELFORMAT,,}-count${STREAM_COUNT}.raw"

mkdir -p "${LOG_DIR}" "${CAP_DIR}"

if [[ ${EUID} -ne 0 ]]; then
	echo "run as root: sudo $0" >&2
	exit 1
fi

log() {
	echo "[${TS}] $*" | tee -a "${LOGFILE}"
}

DMESG_PID=""
cleanup() {
	local rc=$?
	if [[ -n "${DMESG_PID}" ]] && kill -0 "${DMESG_PID}" >/dev/null 2>&1; then
		kill "${DMESG_PID}" >/dev/null 2>&1 || true
		wait "${DMESG_PID}" 2>/dev/null || true
	fi
	chmod -R a+rX "${CAP_DIR}" 2>/dev/null || true
	chmod a+r "${LOGFILE}" "${DMESG_LOG}" "${POST_DMESG_LOG}" 2>/dev/null || true
	if [[ -n "${SUDO_UID:-}" && -n "${SUDO_GID:-}" ]]; then
		chown -R "${SUDO_UID}:${SUDO_GID}" "${CAP_DIR}" 2>/dev/null || true
		chown "${SUDO_UID}:${SUDO_GID}" "${LOGFILE}" "${DMESG_LOG}" "${POST_DMESG_LOG}" 2>/dev/null || true
	fi
	exit "${rc}"
}
trap cleanup EXIT

log "starting manual direct V4L2 stream test"
log "device=${DEVICE}"
log "format=${WIDTH}x${HEIGHT} ${PIXELFORMAT}"
log "sensor_mode=${SENSOR_MODE}"
log "stream_count=${STREAM_COUNT}"
log "timeout=${CAPTURE_TIMEOUT_SEC}s"
log "out_file=${OUT_FILE}"
log "cmdline=$(cat /proc/cmdline)"

if [[ ! -e "${DEVICE}" ]]; then
	log "device missing: ${DEVICE}"
	exit 1
fi

{
	echo "# list-devices"
	v4l2-ctl --list-devices 2>&1 || true
	echo
	echo "# list-formats-ext"
	v4l2-ctl -d "${DEVICE}" --list-formats-ext 2>&1 || true
	echo
	echo "# controls"
	v4l2-ctl -d "${DEVICE}" --list-ctrls 2>&1 || true
	echo
	echo "# all"
	v4l2-ctl -d "${DEVICE}" --all 2>&1 || true
} > "${CAP_DIR}/pre-v4l2-state.log" 2>&1

BYPASS_ARGS=()
if v4l2-ctl -d "${DEVICE}" --list-ctrls 2>/dev/null | grep -q '^ *bypass_mode '; then
	BYPASS_ARGS+=(--set-ctrl bypass_mode=0)
	log "detected bypass_mode control; will set bypass_mode=0"
else
	log "bypass_mode control not present; skipping"
fi

stdbuf -oL dmesg -w > "${DMESG_LOG}" 2>&1 &
DMESG_PID=$!

set +e
timeout --foreground "${CAPTURE_TIMEOUT_SEC}s" v4l2-ctl -d "${DEVICE}" \
	--set-fmt-video=width="${WIDTH}",height="${HEIGHT}",pixelformat="${PIXELFORMAT}" \
	--set-ctrl sensor_mode="${SENSOR_MODE}" \
	"${BYPASS_ARGS[@]}" \
	--stream-mmap \
	--stream-count="${STREAM_COUNT}" \
	--stream-to="${OUT_FILE}" \
	--verbose 2>&1 | tee -a "${LOGFILE}"
RC=${PIPESTATUS[0]}
set -e

if [[ -n "${DMESG_PID}" ]] && kill -0 "${DMESG_PID}" >/dev/null 2>&1; then
	kill "${DMESG_PID}" >/dev/null 2>&1 || true
	wait "${DMESG_PID}" 2>/dev/null || true
fi

dmesg | tail -n 220 > "${POST_DMESG_LOG}" 2>&1 || true

log "capture rc=${RC}"
if [[ -f "${OUT_FILE}" ]]; then
	stat --printf="[${TS}] raw size=%s bytes path=%n\n" "${OUT_FILE}" | tee -a "${LOGFILE}"
else
	log "raw file missing: ${OUT_FILE}"
fi

sync
log "saved pre-state=${CAP_DIR}/pre-v4l2-state.log"
log "saved live dmesg=${DMESG_LOG}"
log "saved post dmesg=${POST_DMESG_LOG}"
exit "${RC}"

