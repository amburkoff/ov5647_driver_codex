#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TS="$(date -u +%Y%m%dT%H%M%SZ)"
LOG_DIR="${ROOT_DIR}/logs"
TRACE_LOG="${LOG_DIR}/${TS}-rmmod-live-dmesg.log"
RUN_LOG="${LOG_DIR}/${TS}-rmmod-trace.log"
DEVNODE_LOG="${LOG_DIR}/${TS}-rmmod-devnodes.log"
FUSER_LOG="${LOG_DIR}/${TS}-rmmod-fuser.log"
LSOF_LOG="${LOG_DIR}/${TS}-rmmod-lsof.log"
SYSRQ_LOG="${LOG_DIR}/${TS}-rmmod-sysrq-watchdog.log"
SYSRQ_DELAY="${RMMOD_SYSRQ_DELAY_SEC:-0}"

mkdir -p "${LOG_DIR}"

echo "[${TS}] starting live dmesg capture" | tee "${RUN_LOG}"
sync

(
	dmesg -W 2>&1 | while IFS= read -r line; do
		printf '%s\n' "${line}"
		sync
	done
) > "${TRACE_LOG}" &
DMESG_PID=$!
SYSRQ_PID=""

cleanup() {
	if kill -0 "${DMESG_PID}" >/dev/null 2>&1; then
		kill "${DMESG_PID}" >/dev/null 2>&1 || true
		wait "${DMESG_PID}" 2>/dev/null || true
	fi
	if [[ -n "${SYSRQ_PID}" ]] && kill -0 "${SYSRQ_PID}" >/dev/null 2>&1; then
		kill "${SYSRQ_PID}" >/dev/null 2>&1 || true
		wait "${SYSRQ_PID}" 2>/dev/null || true
	fi
}
trap cleanup EXIT

sleep 1
echo "[${TS}] collecting pre-rmmod state" | tee -a "${RUN_LOG}"
lsmod | grep -E '^nv_ov5647\\b' | tee -a "${RUN_LOG}" || true
sync
mapfile -t DEVICES < <(find /dev -maxdepth 1 \
	\( -name 'media*' -o -name 'video*' -o -name 'v4l-subdev*' \) \
	-print 2>/dev/null | sort)
printf '%s\n' "${DEVICES[@]}" > "${DEVNODE_LOG}"
if ((${#DEVICES[@]})); then
	fuser -v "${DEVICES[@]}" > "${FUSER_LOG}" 2>&1 || true
	lsof "${DEVICES[@]}" > "${LSOF_LOG}" 2>&1 || true
else
	echo "no media/video/subdev nodes found" > "${FUSER_LOG}"
	echo "no media/video/subdev nodes found" > "${LSOF_LOG}"
fi
sync
sudo dmesg | tail -n 120 > "${LOG_DIR}/${TS}-rmmod-pre-dmesg-tail.log" 2>&1 || true
sync
if [[ "${SYSRQ_DELAY}" =~ ^[0-9]+$ ]] && ((SYSRQ_DELAY > 0)); then
	echo "[${TS}] arming sysrq watchdog delay=${SYSRQ_DELAY}s" | tee -a "${RUN_LOG}"
	(
		sleep "${SYSRQ_DELAY}"
		{
			echo "[${TS}] sysrq watchdog firing after ${SYSRQ_DELAY}s"
			echo w | sudo tee /proc/sysrq-trigger >/dev/null
			echo t | sudo tee /proc/sysrq-trigger >/dev/null
			sync
		} >> "${SYSRQ_LOG}" 2>&1
	) &
	SYSRQ_PID=$!
	sync
else
	echo "[${TS}] sysrq watchdog disabled" > "${SYSRQ_LOG}"
fi
echo "[${TS}] running: rmmod nv_ov5647" | tee -a "${RUN_LOG}"
sync
sudo rmmod nv_ov5647
RC=$?
echo "[${TS}] rmmod rc=${RC}" | tee -a "${RUN_LOG}"
sync
sleep 1
exit "${RC}"
