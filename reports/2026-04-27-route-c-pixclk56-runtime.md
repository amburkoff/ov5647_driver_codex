# 2026-04-27 Route-C `pix_clk_hz=56004480` Runtime Retest

## Goal

Validate whether correcting the canonical route-C `pix_clk_hz` from `58333000`
to `56004480` changes the long-standing no-ingress failure signature on Jetson
Orin NX / L4T `r36.5`.

This retest follows NVIDIA support guidance to review Sensor Pixel Clock.

## Inputs

Boot profile after reboot:

- `boot_profile=ov5647-dev`

Verified live DT mode fields after reboot:

- `pix_clk_hz = 56004480`
- `mclk_khz = 24000`
- `tegra_sinterface = "serial_c"`
- `num_lanes = 2`
- `lane_polarity = 0`
- `discontinuous_clk = "yes"`
- `cil_settletime = 0`

Manual commands run by the user:

```bash
sudo /home/cam/ov5647_driver_codex/scripts/run_manual_insmod_diag.sh full-delay-dump
sudo /home/cam/ov5647_driver_codex/scripts/run_manual_single_frame_rtcpu_trace.sh
```

Runtime artifacts:

- trace dir: `artifacts/traces/20260427T092149Z`
- dmesg log: `logs/20260427T092149Z-single-frame-rtcpu-live-dmesg.log`

## Runtime Result

Manual `insmod` succeeded:

- module `srcversion = ADC5D388AC61C3B9AA9276E`
- `insmod rc = 0`

Single-frame capture reached stream start but still timed out:

- `VIDIOC_STREAMON returned 0 (Success)`
- `capture rc = 124`
- raw output size remained `0 bytes`

Repeated VI timeout remained:

- `tegra-camrtc-capture-vi: uncorr_err: request timed out after 2500 ms`

## RTCPU/NVCSI Trace Result

`scripts/analyze_rtcpu_trace.sh` on `20260427T092149Z` still reports:

- `capture_event_sof = 0`
- `capture_event_eof = 0`
- `capture_event_error = 0`
- `rtcpu_nvcsi_intr = 0`
- `rtcpu_vinotify_error = 0`
- `vi_frame_begin = 0`
- `vi_frame_end = 0`

Control-path events still exist:

- `capture_setup = 1`
- `capture_ivc_send = 9`
- `capture_ivc_recv = 5`
- `vi_task_submit = 4`
- `stream_on_calls = 6`

Resulting diagnosis remains unchanged:

- `receiver_signature=no_receiver_ingress_visible`

## Sensor Register Lifecycle

The new `pix_clk_hz` value did not change the sensor-side stream lifecycle.

Key registers remained:

| Phase | `0x0100` | `0x300d` | `0x4202` | `0x4800` | `0x503d` |
|---|---|---|---|---|---|
| `after_stream_on` | `0x01` | `0x00` | `0x00` | `0x34` | `0x00` |
| `before_stream_off` | `0x01` | `0x00` | `0x00` | `0x34` | `0x00` |
| `after_stream_off` | `0x00` | `0x01` | `0x0f` | `0x25` | `0x00` |

So the corrected `pix_clk_hz` still leaves the sensor apparently streaming
until the stack explicitly stops it after timeout.

## Conclusion

This controlled NVIDIA-guided `pix_clk_hz` retest is negative.

What changed:

- live DT now uses the self-consistent `pix_clk_hz = 56004480`

What did not change:

- `VIDIOC_STREAMON` success
- zero-byte raw output
- repeated VI timeout
- no `SOF`
- no `rtcpu_nvcsi_intr`
- no `vi_frame_begin/end`
- same sensor-side stream-state persistence through timeout

Practical conclusion:

- the remaining software-only `pix_clk_hz` mismatch hypothesis is now also
  substantially weakened;
- this does not look like the root cause of the missing CSI ingress on the
  current hardware path.
