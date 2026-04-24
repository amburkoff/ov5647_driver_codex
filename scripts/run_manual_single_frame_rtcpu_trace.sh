#!/usr/bin/env bash
set -euo pipefail
shopt -s nullglob

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TS="$(date -u +%Y%m%dT%H%M%SZ)"
LOG_DIR="${ROOT_DIR}/logs"
CAP_DIR="${ROOT_DIR}/artifacts/captures/${TS}"
TRACE_DIR="${ROOT_DIR}/artifacts/traces/${TS}"
RUN_LOG="${LOG_DIR}/${TS}-single-frame-rtcpu-trace.log"
DMESG_LOG="${LOG_DIR}/${TS}-single-frame-rtcpu-live-dmesg.log"
POST_DMESG_LOG="${LOG_DIR}/${TS}-single-frame-rtcpu-post-dmesg-tail.log"
RAW_OUT="${CAP_DIR}/ov5647-640x480-bg10.raw"
CAPTURE_TIMEOUT_SEC="${CAPTURE_TIMEOUT_SEC:-30}"
TRACEFS="${TRACEFS:-/sys/kernel/debug/tracing}"
CLOCK_PM_HELPER="${ROOT_DIR}/scripts/collect_clk_pm_state.sh"
CLK_PM_SAMPLE_INTERVAL_SEC="${CLK_PM_SAMPLE_INTERVAL_SEC:-1}"
CLK_PM_SAMPLES_DIR="${TRACE_DIR}/clk-pm-samples"

EVENTS=(
	"camera_common/camera_common_s_power"
	"camera_common/csi_s_power"
	"camera_common/csi_s_stream"
	"camera_common/tegra_channel_capture_done"
	"camera_common/tegra_channel_capture_frame"
	"camera_common/tegra_channel_capture_setup"
	"camera_common/tegra_channel_notify_status_callback"
	"camera_common/tegra_channel_set_power"
	"camera_common/tegra_channel_set_stream"
	"camera_common/vi_task_submit"
	"tegra_capture/capture_event_eof"
	"tegra_capture/capture_event_error"
	"tegra_capture/capture_event_sof"
	"tegra_capture/capture_event_wdt"
	"tegra_capture/capture_ivc_recv"
	"tegra_capture/capture_ivc_send"
	"tegra_rtcpu/rtcpu_nvcsi_intr"
	"tegra_rtcpu/rtcpu_vinotify_error"
	"tegra_rtcpu/rtcpu_vinotify_event"
	"tegra_rtcpu/rtcpu_vinotify_event_ts64"
	"tegra_rtcpu/vi_frame_begin"
	"tegra_rtcpu/vi_frame_end"
)

if [[ ${EUID} -ne 0 ]]; then
	echo "run as root: sudo $0" >&2
	exit 1
fi

mkdir -p "${LOG_DIR}" "${CAP_DIR}" "${TRACE_DIR}"

log() {
	echo "[${TS}] $*" | tee -a "${RUN_LOG}"
}

write_tracefs() {
	local path="$1"
	local value="$2"

	if [[ -w "${path}" ]]; then
		printf '%s\n' "${value}" > "${path}" 2>/dev/null || true
	fi
}

enable_event() {
	local event="$1"
	local enable_path="${TRACEFS}/events/${event}/enable"

	if [[ -w "${enable_path}" ]]; then
		printf '1\n' > "${enable_path}" 2>/dev/null || true
		printf '%s\n' "${event}" >> "${TRACE_DIR}/enabled-events.log"
	else
		printf '%s\n' "${event}" >> "${TRACE_DIR}/missing-events.log"
	fi
}

disable_event() {
	local event="$1"
	local enable_path="${TRACEFS}/events/${event}/enable"

	if [[ -w "${enable_path}" ]]; then
		printf '0\n' > "${enable_path}" 2>/dev/null || true
	fi
}

copy_trace_state() {
	local phase="$1"

	cp "${TRACEFS}/trace" "${TRACE_DIR}/${phase}-trace.log" 2>/dev/null || true
	cp "${TRACEFS}/set_event" "${TRACE_DIR}/${phase}-set_event.log" 2>/dev/null || true
	cp "${TRACEFS}/trace_clock" "${TRACE_DIR}/${phase}-trace_clock.log" 2>/dev/null || true
	cp "${TRACEFS}/tracing_on" "${TRACE_DIR}/${phase}-tracing_on.log" 2>/dev/null || true
	if [[ -d /sys/kernel/debug/tegra_rtcpu_trace ]]; then
		cp /sys/kernel/debug/tegra_rtcpu_trace/* "${TRACE_DIR}/" 2>/dev/null || true
	fi
}

collect_clk_pm_state() {
	local phase="$1"

	if [[ -x "${CLOCK_PM_HELPER}" ]]; then
		"${CLOCK_PM_HELPER}" "${TRACE_DIR}/clk-pm-${phase}" >> "${RUN_LOG}" 2>&1 || true
	fi
}

fix_artifact_permissions() {
	chmod -R a+rX "${TRACE_DIR}" "${CAP_DIR}" 2>/dev/null || true
	chmod a+r "${RUN_LOG}" "${DMESG_LOG}" "${POST_DMESG_LOG}" 2>/dev/null || true
	if [[ -n "${SUDO_UID:-}" && -n "${SUDO_GID:-}" ]]; then
		chown -R "${SUDO_UID}:${SUDO_GID}" "${TRACE_DIR}" "${CAP_DIR}" 2>/dev/null || true
		chown "${SUDO_UID}:${SUDO_GID}" "${RUN_LOG}" "${DMESG_LOG}" "${POST_DMESG_LOG}" 2>/dev/null || true
	fi
}

DMESG_PID=""
CLK_PM_SAMPLER_PID=""
stop_clk_pm_sampler() {
	if [[ -n "${CLK_PM_SAMPLER_PID}" ]] && kill -0 "${CLK_PM_SAMPLER_PID}" >/dev/null 2>&1; then
		kill "${CLK_PM_SAMPLER_PID}" >/dev/null 2>&1 || true
		wait "${CLK_PM_SAMPLER_PID}" 2>/dev/null || true
	fi
}

start_clk_pm_sampler() {
	local interval="$1"
	local sample_idx=0

	mkdir -p "${CLK_PM_SAMPLES_DIR}"

	(
		while true; do
			local sample_dir
			printf -v sample_dir "%s/sample-%04d" "${CLK_PM_SAMPLES_DIR}" "${sample_idx}"
			if [[ -x "${CLOCK_PM_HELPER}" ]]; then
				"${CLOCK_PM_HELPER}" "${sample_dir}" >> "${RUN_LOG}" 2>&1 || true
			fi
			sample_idx=$((sample_idx + 1))
			sleep "${interval}" || exit 0
		done
	) &
	CLK_PM_SAMPLER_PID=$!
	log "started clk/pm sampler pid=${CLK_PM_SAMPLER_PID} interval=${interval}s"
}

cleanup() {
	local rc=$?

	write_tracefs "${TRACEFS}/tracing_on" 0
	copy_trace_state "final"
	stop_clk_pm_sampler
	for event in "${EVENTS[@]}"; do
		disable_event "${event}"
	done
	if [[ -n "${DMESG_PID}" ]] && kill -0 "${DMESG_PID}" >/dev/null 2>&1; then
		kill "${DMESG_PID}" >/dev/null 2>&1 || true
		wait "${DMESG_PID}" 2>/dev/null || true
	fi
	fix_artifact_permissions
	sync
	exit "${rc}"
}
trap cleanup EXIT

log "starting RTCPU/NVCSI traced single-frame capture"
log "trace dir=${TRACE_DIR}"
log "raw out=${RAW_OUT}"
log "timeout=${CAPTURE_TIMEOUT_SEC}s"
log "clk/pm sample interval=${CLK_PM_SAMPLE_INTERVAL_SEC}s"

{
	echo "# cmdline"
	cat /proc/cmdline
	echo
	echo "# module state"
	lsmod | grep nv_ov5647 || true
	echo
	echo "# module params"
	param_files=(/sys/module/nv_ov5647/parameters/*)
	if ((${#param_files[@]} == 0)); then
		echo "nv_ov5647 parameter files not found; is the module loaded?"
	else
		for f in "${param_files[@]}"; do
			printf '%s=' "${f}"
			cat "${f}" 2>&1 || true
		done
	fi
	echo
	echo "# video nodes"
	ls -l /dev/video* /dev/media* /dev/v4l-subdev* 2>&1 || true
	echo
	echo "# v4l2"
	v4l2-ctl -d /dev/video0 --all 2>&1 || true
	echo
	echo "# media"
	media-ctl -p 2>&1 || true
} > "${TRACE_DIR}/pre-capture-state.log" 2>&1

write_tracefs "${TRACEFS}/tracing_on" 0
write_tracefs "${TRACEFS}/current_tracer" nop
write_tracefs "${TRACEFS}/trace_clock" mono
write_tracefs "${TRACEFS}/buffer_size_kb" 8192
write_tracefs "${TRACEFS}/trace" ""

: > "${TRACE_DIR}/enabled-events.log"
: > "${TRACE_DIR}/missing-events.log"
for event in "${EVENTS[@]}"; do
	enable_event "${event}"
done

copy_trace_state "before"
collect_clk_pm_state "before"
write_tracefs "${TRACEFS}/trace_marker" "ov5647_rtcpu_trace_capture_begin ${TS}"
write_tracefs "${TRACEFS}/tracing_on" 1

stdbuf -oL dmesg -w > "${DMESG_LOG}" 2>&1 &
DMESG_PID=$!

sleep 1
start_clk_pm_sampler "${CLK_PM_SAMPLE_INTERVAL_SEC}"
log "running v4l2 single-frame capture"
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

stop_clk_pm_sampler
write_tracefs "${TRACEFS}/trace_marker" "ov5647_rtcpu_trace_capture_end ${TS} rc=${RC}"
write_tracefs "${TRACEFS}/tracing_on" 0
copy_trace_state "after"
collect_clk_pm_state "after"

log "capture rc=${RC}"
if [[ -f "${RAW_OUT}" ]]; then
	stat --printf="[${TS}] raw size=%s bytes path=%n\n" "${RAW_OUT}" | tee -a "${RUN_LOG}"
else
	log "raw file missing: ${RAW_OUT}"
fi

dmesg | tail -n 220 > "${POST_DMESG_LOG}" 2>&1 || true
log "saved trace dir=${TRACE_DIR}"
log "saved dmesg log=${DMESG_LOG}"
exit "${RC}"
