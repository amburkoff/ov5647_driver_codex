#!/usr/bin/env bash
set -euo pipefail

usage() {
	cat <<'EOF'
Usage:
  analyze_rtcpu_trace.sh <trace-dir-or-trace-file>

Examples:
  ./scripts/analyze_rtcpu_trace.sh artifacts/traces/20260423T141837Z
  ./scripts/analyze_rtcpu_trace.sh artifacts/traces/20260423T141837Z/final-trace.log
EOF
}

if [[ $# -ne 1 ]]; then
	usage >&2
	exit 1
fi

INPUT="$1"
TRACE_FILE=""
EVENTS_FILE=""

if [[ -d "${INPUT}" ]]; then
	if [[ -f "${INPUT}/final-trace.log" ]]; then
		TRACE_FILE="${INPUT}/final-trace.log"
	elif [[ -f "${INPUT}/after-trace.log" ]]; then
		TRACE_FILE="${INPUT}/after-trace.log"
	else
		echo "no final-trace.log or after-trace.log under ${INPUT}" >&2
		exit 1
	fi

	if [[ -f "${INPUT}/enabled-events.log" ]]; then
		EVENTS_FILE="${INPUT}/enabled-events.log"
	fi
elif [[ -f "${INPUT}" ]]; then
	TRACE_FILE="${INPUT}"
	TRACE_DIR="$(cd "$(dirname "${INPUT}")" && pwd)"
	if [[ -f "${TRACE_DIR}/enabled-events.log" ]]; then
		EVENTS_FILE="${TRACE_DIR}/enabled-events.log"
	fi
else
	echo "input not found: ${INPUT}" >&2
	exit 1
fi

TRACE_PATH="$(cd "$(dirname "${TRACE_FILE}")" && pwd)/$(basename "${TRACE_FILE}")"

count_event() {
	local event="$1"
	grep -c -F ": ${event}:" "${TRACE_FILE}" || true
}

print_signal() {
	local label="$1"
	local event="$2"
	local count
	count="$(count_event "${event}")"
	printf "%-22s %5s\n" "${label}" "${count}"
}

echo "trace_file=${TRACE_PATH}"

if [[ -n "${EVENTS_FILE}" ]]; then
	echo "enabled_events_file=${EVENTS_FILE}"
	echo "enabled_events_count=$(wc -l < "${EVENTS_FILE}")"
fi

echo
echo "Key Receiver Events"
print_signal "capture_event_sof" "capture_event_sof"
print_signal "capture_event_eof" "capture_event_eof"
print_signal "capture_event_error" "capture_event_error"
print_signal "capture_event_wdt" "capture_event_wdt"
print_signal "rtcpu_nvcsi_intr" "rtcpu_nvcsi_intr"
print_signal "rtcpu_vinotify_error" "rtcpu_vinotify_error"
print_signal "rtcpu_vinotify_event" "rtcpu_vinotify_event"
print_signal "vi_frame_begin" "vi_frame_begin"
print_signal "vi_frame_end" "vi_frame_end"

echo
echo "Pipeline Control Events"
print_signal "capture_setup" "tegra_channel_capture_setup"
print_signal "stream_on_calls" "tegra_channel_set_stream"
print_signal "power_calls" "tegra_channel_set_power"
print_signal "capture_ivc_send" "capture_ivc_send"
print_signal "capture_ivc_recv" "capture_ivc_recv"
print_signal "vi_task_submit" "vi_task_submit"

echo
echo "Diagnosis"

sof_count="$(count_event "capture_event_sof")"
eof_count="$(count_event "capture_event_eof")"
nvcsi_intr_count="$(count_event "rtcpu_nvcsi_intr")"
vi_begin_count="$(count_event "vi_frame_begin")"
vinotify_err_count="$(count_event "rtcpu_vinotify_error")"
cap_err_count="$(count_event "capture_event_error")"

if [[ "${sof_count}" -eq 0 && "${eof_count}" -eq 0 && "${nvcsi_intr_count}" -eq 0 && "${vi_begin_count}" -eq 0 && "${vinotify_err_count}" -eq 0 && "${cap_err_count}" -eq 0 ]]; then
	echo "receiver_signature=no_receiver_ingress_visible"
	echo "summary=stream-control path reached NVCSI/VI handoff, but trace shows no SOF/EOF/NVCSI/VI frame events"
elif [[ "${sof_count}" -eq 0 && ( "${nvcsi_intr_count}" -gt 0 || "${vinotify_err_count}" -gt 0 || "${cap_err_count}" -gt 0 ) ]]; then
	echo "receiver_signature=receiver_sees_errors_without_frame"
	echo "summary=receiver-side activity exists, but no frame-start reached capture path"
else
	echo "receiver_signature=receiver_activity_present"
	echo "summary=trace contains some receiver-side frame or error activity; inspect raw log for sequence details"
fi
