#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TS="$(date -u +%Y%m%dT%H%M%SZ)"
LOG_DIR="${ROOT_DIR}/logs"
CAP_DIR="${ROOT_DIR}/artifacts/captures/${TS}"
TRACE_LOG="${LOG_DIR}/${TS}-stream-live-dmesg.log"
RUN_LOG="${LOG_DIR}/${TS}-single-frame-trace.log"
RAW_OUT="${CAP_DIR}/ov5647-640x480-bg10.raw"

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
v4l2-ctl -d /dev/video0 \
	--set-fmt-video=width=640,height=480,pixelformat=BG10 \
	--set-ctrl sensor_mode=0 \
	--stream-mmap \
	--stream-count=1 \
	--stream-to="${RAW_OUT}" \
	--verbose | tee -a "${RUN_LOG}"
RC=${PIPESTATUS[0]}
echo "[${TS}] capture rc=${RC}" | tee -a "${RUN_LOG}"
sleep 1
exit "${RC}"
