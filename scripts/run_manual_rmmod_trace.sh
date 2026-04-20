#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TS="$(date -u +%Y%m%dT%H%M%SZ)"
LOG_DIR="${ROOT_DIR}/logs"
TRACE_LOG="${LOG_DIR}/${TS}-rmmod-live-dmesg.log"
RUN_LOG="${LOG_DIR}/${TS}-rmmod-trace.log"

mkdir -p "${LOG_DIR}"

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
echo "[${TS}] running: rmmod nv_ov5647" | tee -a "${RUN_LOG}"
rmmod nv_ov5647
RC=$?
echo "[${TS}] rmmod rc=${RC}" | tee -a "${RUN_LOG}"
sleep 1
exit "${RC}"
