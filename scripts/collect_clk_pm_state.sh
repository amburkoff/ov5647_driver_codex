#!/usr/bin/env bash
set -euo pipefail
shopt -s nullglob

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TS="$(date -u +%Y%m%dT%H%M%SZ)"
LOG_DIR="${ROOT_DIR}/logs"
DEFAULT_OUT_DIR="${ROOT_DIR}/artifacts/clk-pm-state/${TS}"
OUT_DIR="${1:-${DEFAULT_OUT_DIR}}"
RUN_LOG="${LOG_DIR}/${TS}-collect-clk-pm-state.log"

CLK_DIRS=(
	"/sys/kernel/debug/clk/extperiph1"
	"/sys/kernel/debug/clk/nvcsi"
	"/sys/kernel/debug/clk/nvcsilp"
	"/sys/kernel/debug/clk/vi"
)

PM_DIRS=(
	"/sys/kernel/debug/pm_genpd/vi"
	"/sys/kernel/debug/pm_genpd/ispa"
)

CLK_FIELDS=(
	"clk_rate"
	"clk_parent"
	"clk_enable_count"
	"clk_prepare_count"
	"clk_protect_count"
	"clk_min_rate"
	"clk_max_rate"
)

PM_FIELDS=(
	"current_state"
	"active_time"
	"total_idle_time"
	"devices"
	"sub_domains"
)

if [[ ${EUID} -ne 0 ]]; then
	echo "run as root: sudo $0 [out-dir]" >&2
	exit 1
fi

mkdir -p "${LOG_DIR}" "${OUT_DIR}"

log() {
	echo "[${TS}] $*" | tee -a "${RUN_LOG}"
}

copy_optional() {
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

log "starting clk/pm state collection"
log "out dir=${OUT_DIR}"

{
	echo "# cmdline"
	cat /proc/cmdline
	echo
	echo "# debugfs mount"
	mount | grep debugfs || true
	echo
	echo "# lsmod camera-related"
	lsmod | grep -E 'nv_ov5647|nvhost_(nvcsi|vi5|capture)|tegra_camera|capture_ivc|ivc_bus|hsp_mailbox' || true
} > "${OUT_DIR}/pre-state.log" 2>&1

mkdir -p "${OUT_DIR}/clk" "${OUT_DIR}/pm_genpd"

for dir in "${CLK_DIRS[@]}"; do
	base="$(basename "${dir}")"
	mkdir -p "${OUT_DIR}/clk/${base}"
	for field in "${CLK_FIELDS[@]}"; do
		copy_optional "${dir}/${field}" "${OUT_DIR}/clk/${base}/${field}.log"
	done
done

for dir in "${PM_DIRS[@]}"; do
	base="$(basename "${dir}")"
	mkdir -p "${OUT_DIR}/pm_genpd/${base}"
	for field in "${PM_FIELDS[@]}"; do
		copy_optional "${dir}/${field}" "${OUT_DIR}/pm_genpd/${base}/${field}.log"
	done
done

log "saved clk and pm_genpd state under ${OUT_DIR}"
