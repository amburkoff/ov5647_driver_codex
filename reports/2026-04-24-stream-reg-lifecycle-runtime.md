# Stream Register Lifecycle Runtime Result

Date: 2026-04-24

## Goal

Use the new compact OV5647 register lifecycle dump to answer a narrower
question:

- does the sensor-side stream state collapse during the failed capture window,
  or
- does the sensor still look like it is streaming while Jetson never sees
  receiver ingress?

## Commands

```bash
sudo /home/cam/ov5647_driver_codex/scripts/run_manual_rmmod_trace.sh
sudo /home/cam/ov5647_driver_codex/scripts/run_manual_insmod_diag.sh full-delay-dump
sudo /home/cam/ov5647_driver_codex/scripts/run_manual_single_frame_rtcpu_trace.sh
```

## Artifacts

- unload trace:
  - `logs/20260424T144134Z-rmmod-trace.log`
- insmod logs:
  - `logs/20260424T144144Z-manual-insmod-full-delay-dump.log`
  - `logs/20260424T144144Z-manual-insmod-full-delay-dump.modinfo.log`
  - `logs/20260424T144144Z-manual-insmod-full-delay-dump.dmesg-tail.log`
- traced capture:
  - `artifacts/traces/20260424T144154Z/`
  - `logs/20260424T144154Z-single-frame-rtcpu-live-dmesg.log`

## High-Level Result

- `rmmod rc=0`
- `insmod rc=0`
- rebuilt module loaded:
  - `srcversion = ADC5D388AC61C3B9AA9276E`
- `VIDIOC_STREAMON returned 0 (Success)`
- capture timed out with `rc=124`
- raw output remained `0 bytes`

## Key Sensor-Side Register Comparison

Selected key registers:

| Phase | `0x0100` | `0x300d` | `0x4202` | `0x4800` | `0x503d` |
|---|---|---|---|---|---|
| `after_stream_on` | `0x01` | `0x00` | `0x00` | `0x34` | `0x00` |
| `before_stream_off` | `0x01` | `0x00` | `0x00` | `0x34` | `0x00` |
| `after_stream_off` | `0x00` | `0x01` | `0x0f` | `0x25` | `0x00` |

Interpretation:

- `after_stream_on` and `before_stream_off` match exactly on the key
  stream-state registers;
- the sensor still looks like it is streaming when the Jetson stack reaches
  timeout cleanup;
- only `after_stream_off` returns the sensor to expected standby/LP11 state.

## Receiver-Side Context

The same run still showed the known receiver-side signature:

- repeated `tegra-camrtc-capture-vi: uncorr_err: request timed out after 2500 ms`
- control-path trace activity only
- no:
  - `capture_event_sof`
  - `capture_event_eof`
  - `rtcpu_nvcsi_intr`
  - `vi_frame_begin`
  - `vi_frame_end`

## Conclusion

This runtime result weakens the remaining hypothesis that the OV5647 falls out
of stream during the failed capture window.

Instead, the sensor-side state remains consistent with active streaming until
the Jetson stack explicitly stops it, while the receiver side still never sees
observable frame ingress.
