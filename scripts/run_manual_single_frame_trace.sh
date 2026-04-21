#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TS="$(date -u +%Y%m%dT%H%M%SZ)"
LOG_DIR="${ROOT_DIR}/logs"
CAP_DIR="${ROOT_DIR}/artifacts/captures/${TS}"
TRACE_LOG="${LOG_DIR}/${TS}-stream-live-dmesg.log"
RUN_LOG="${LOG_DIR}/${TS}-single-frame-trace.log"
RAW_OUT="${CAP_DIR}/ov5647-640x480-bg10.raw"
POST_DMESG_LOG="${LOG_DIR}/${TS}-single-frame-post-dmesg-tail.log"
CAPTURE_TIMEOUT_SEC="${CAPTURE_TIMEOUT_SEC:-30}"

mkdir -p "${LOG_DIR}" "${CAP_DIR}"

echo "[${TS}] starting live dmesg capture" | tee "${RUN_LOG}"

stdbuf -oL dmesg -w > "${TRACE_LOG}" 2>&1 &
DMESG_PID=$!

cleanup() {
	if kill -0 "${DMESG_PID}" >/dev/null 2>&1; then
		kill "${DMESG_PID}" >/dev/null 2>&1 || true
		wait "${DMESG_PID}" 2>/dev/null || true
	fi
}
trap cleanup EXIT

sleep 1
echo "[${TS}] running single-frame capture to ${RAW_OUT}" | tee -a "${RUN_LOG}"
echo "[${TS}] timeout=${CAPTURE_TIMEOUT_SEC}s" | tee -a "${RUN_LOG}"
set +e
timeout --foreground "${CAPTURE_TIMEOUT_SEC}s" v4l2-ctl -d /dev/video0 \
	--set-fmt-video=width=640,height=480,pixelformat=BG10 \
	--set-ctrl sensor_mode=0 \
	--stream-mmap \
	--stream-count=1 \
	--stream-to="${RAW_OUT}" \
	--verbose 2>&1 | tee -a "${RUN_LOG}"
RC=${PIPESTATUS[0]}
set -e
echo "[${TS}] capture rc=${RC}" | tee -a "${RUN_LOG}"
if [[ -f "${RAW_OUT}" ]]; then
	stat --printf="[${TS}] raw size=%s bytes path=%n\n" "${RAW_OUT}" | tee -a "${RUN_LOG}"
else
	echo "[${TS}] raw file missing: ${RAW_OUT}" | tee -a "${RUN_LOG}"
fi
sudo dmesg | tail -n 160 > "${POST_DMESG_LOG}" 2>&1 || true
sync
sleep 1
exit "${RC}"
