#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TS="$(date -u +%Y%m%dT%H%M%SZ)"
LOG_DIR="${ROOT_DIR}/logs"
LOGFILE="${LOG_DIR}/${TS}-manual-bpmp-clock-boost.log"

CLK_ROOT="/sys/kernel/debug/bpmp/debug/clk"
CLOCKS=(vi isp nvcsi emc)

mkdir -p "${LOG_DIR}"

if [[ ${EUID} -ne 0 ]]; then
	echo "run as root: sudo $0" >&2
	exit 1
fi

log() {
	echo "[${TS}] $*" | tee -a "${LOGFILE}"
}

read_file() {
	local path="$1"
	if [[ -r "${path}" ]]; then
		cat "${path}"
	else
		echo "<unreadable>"
	fi
}

write_value() {
	local path="$1"
	local value="$2"
	printf '%s\n' "${value}" > "${path}"
}

log "starting manual BPMP clock boost"
log "clk_root=${CLK_ROOT}"
log "cmdline=$(cat /proc/cmdline)"

for clk in "${CLOCKS[@]}"; do
	base="${CLK_ROOT}/${clk}"
	if [[ ! -d "${base}" ]]; then
		log "missing clock node: ${base}"
		exit 1
	fi

	log "before ${clk}:"
	log "  rate=$(read_file "${base}/rate")"
	log "  max_rate=$(read_file "${base}/max_rate")"
	log "  mrq_rate_locked=$(read_file "${base}/mrq_rate_locked")"
done

for clk in "${CLOCKS[@]}"; do
	base="${CLK_ROOT}/${clk}"
	log "locking ${clk} mrq_rate_locked=1"
	write_value "${base}/mrq_rate_locked" 1
done

for clk in "${CLOCKS[@]}"; do
	base="${CLK_ROOT}/${clk}"
	max_rate="$(read_file "${base}/max_rate")"
	log "setting ${clk} rate=${max_rate}"
	write_value "${base}/rate" "${max_rate}"
done

for clk in "${CLOCKS[@]}"; do
	base="${CLK_ROOT}/${clk}"
	log "after ${clk}:"
	log "  rate=$(read_file "${base}/rate")"
	log "  max_rate=$(read_file "${base}/max_rate")"
	log "  mrq_rate_locked=$(read_file "${base}/mrq_rate_locked")"
done

sync
log "manual BPMP clock boost complete"

