# RTCPU Trace Analysis Helper

Date: 2026-04-23

## Goal

Add a reproducible way to summarize traced capture logs without manually
grepping large `final-trace.log` files.

## Added Helper

- `scripts/analyze_rtcpu_trace.sh`

The helper accepts either:

- a trace directory such as `artifacts/traces/20260423T141837Z`
- or a direct trace file such as `final-trace.log`

It reports counts for:

- `capture_event_sof`
- `capture_event_eof`
- `capture_event_error`
- `capture_event_wdt`
- `rtcpu_nvcsi_intr`
- `rtcpu_vinotify_error`
- `rtcpu_vinotify_event`
- `vi_frame_begin`
- `vi_frame_end`
- control-path markers such as `capture_ivc_send/recv` and `vi_task_submit`

It also emits a compact diagnosis:

- `receiver_signature=no_receiver_ingress_visible`
- `receiver_signature=receiver_sees_errors_without_frame`
- `receiver_signature=receiver_activity_present`

## Example Runtime Result

Applied to:

- `artifacts/traces/20260423T141837Z/final-trace.log`

Saved output:

- `logs/20260423T153140Z-analyze-rtcpu-trace-20260423T141837Z.log`
- `artifacts/traces/20260423T141837Z/analysis-summary.txt`

Summary for that run:

- `capture_setup = 1`
- `capture_ivc_send = 9`
- `capture_ivc_recv = 5`
- `vi_task_submit = 4`
- all receiver ingress events stayed at `0`:
  - `SOF`
  - `EOF`
  - `rtcpu_nvcsi_intr`
  - `rtcpu_vinotify_error`
  - `vi_frame_begin`
  - `vi_frame_end`

Diagnosis:

- `receiver_signature=no_receiver_ingress_visible`

## Practical Value

This helper does not create new hooks, but it makes each manual traced capture
comparable and keeps the same conclusion reproducible across branches:

- control path reaches the capture stack;
- receiver ingress still appears absent on the failing OV5647 path.
