#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TS="$(date -u +%Y%m%dT%H%M%SZ)"
LOG_DIR="${ROOT_DIR}/logs"
MODULE_PATH="${ROOT_DIR}/src/nv_ov5647/nv_ov5647.ko"
PROFILE="${1:-full-delay}"
LOGFILE="${LOG_DIR}/${TS}-manual-insmod-${PROFILE}.log"
MODINFO_LOG="${LOG_DIR}/${TS}-manual-insmod-${PROFILE}.modinfo.log"
DMESG_LOG="${LOG_DIR}/${TS}-manual-insmod-${PROFILE}.dmesg-tail.log"

mkdir -p "${LOG_DIR}"

case "${PROFILE}" in
	full-delay)
		PARAMS=(register_i2c_driver=1 allow_hw_probe=1 unload_marker_delay_ms=500)
		;;
	full-delay-dump)
		PARAMS=(register_i2c_driver=1 allow_hw_probe=1 dump_stream_regs=1 unload_marker_delay_ms=500)
		;;
	full-delay-dump-mclk24)
		PARAMS=(
			register_i2c_driver=1
			allow_hw_probe=1
			dump_stream_regs=1
			mclk_override_hz=24000000
			unload_marker_delay_ms=500
		)
		;;
	full-delay-dump-mclk24-testpat)
		PARAMS=(
			register_i2c_driver=1
			allow_hw_probe=1
			dump_stream_regs=1
			mclk_override_hz=24000000
			ov5647_test_pattern=1
			unload_marker_delay_ms=500
		)
		;;
	full-delay-dump-contclk)
		PARAMS=(register_i2c_driver=1 allow_hw_probe=1 dump_stream_regs=1 continuous_mipi_clock=1 unload_marker_delay_ms=500)
		;;
	full-delay-dump-contclk-mclk24)
		PARAMS=(
			register_i2c_driver=1
			allow_hw_probe=1
			dump_stream_regs=1
			continuous_mipi_clock=1
			mclk_override_hz=24000000
			unload_marker_delay_ms=500
		)
		;;
	skip-register)
		PARAMS=(register_i2c_driver=1 allow_hw_probe=1 skip_v4l2_register=1 unload_marker_delay_ms=500)
		;;
	skip-unregister)
		PARAMS=(register_i2c_driver=1 allow_hw_probe=1 skip_v4l2_unregister=1 unload_marker_delay_ms=500)
		;;
	split-unregister)
		PARAMS=(register_i2c_driver=1 allow_hw_probe=1 split_v4l2_unregister=1 unload_marker_delay_ms=500)
		;;
	*)
		echo "usage: $0 [full-delay|full-delay-dump|full-delay-dump-mclk24|full-delay-dump-mclk24-testpat|full-delay-dump-contclk|full-delay-dump-contclk-mclk24|skip-register|skip-unregister|split-unregister]" \
			>&2
		exit 2
		;;
esac

{
	echo "[${TS}] manual insmod profile=${PROFILE}"
	echo "[${TS}] module=${MODULE_PATH}"
	echo "[${TS}] params=${PARAMS[*]}"
	echo "[${TS}] cmdline=$(cat /proc/cmdline)"
} | tee "${LOGFILE}"
sync

if [[ ! -f "${MODULE_PATH}" ]]; then
	echo "[${TS}] module not found: ${MODULE_PATH}" | tee -a "${LOGFILE}"
	exit 1
fi

if lsmod | awk '$1 == "nv_ov5647" { found = 1 } END { exit(found ? 0 : 1) }'; then
	echo "[${TS}] refusing insmod: nv_ov5647 is already loaded" | tee -a "${LOGFILE}"
	exit 2
fi

modinfo "${MODULE_PATH}" | tee "${MODINFO_LOG}"
sync

echo "[${TS}] running insmod" | tee -a "${LOGFILE}"
sudo insmod "${MODULE_PATH}" "${PARAMS[@]}" 2>&1 | tee -a "${LOGFILE}"
RC=${PIPESTATUS[0]}
sync

sudo dmesg | tail -n 160 > "${DMESG_LOG}" 2>&1 || true
sync

echo "[${TS}] insmod rc=${RC}" | tee -a "${LOGFILE}"
exit "${RC}"
