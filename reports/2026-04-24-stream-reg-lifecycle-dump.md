# Stream Register Lifecycle Dump

Date: 2026-04-24

## Goal

Add one compact sensor-side diagnostic that is still safe enough for the normal
manual traced-capture loop:

- dump key OV5647 registers before stream start
- dump them again after stream start
- dump them again around stream stop after a failed capture timeout

## Why

The existing I2C diagnostics already showed:

- valid chip ID
- valid `STREAMON` bit
- valid test-pattern enable when requested

But they did not yet answer the narrower question:

- does the sensor-side stream state collapse during the failed capture window,
  or
- does the sensor still look like it is streaming while Jetson never sees
  receiver ingress?

## Code Change

Driver file:

- `src/nv_ov5647/nv_ov5647.c`

New dump phases:

- `before_stream_on`
- `before_stream_off`
- `after_stream_off`

Existing phases kept:

- `power_on_lp11`
- `after_set_mode`
- `after_stream_on`

## Build

Build artifact:

- `artifacts/build/20260424T143927Z`

Built module:

- `src/nv_ov5647/nv_ov5647.ko`
- `srcversion = ADC5D388AC61C3B9AA9276E`

Build log:

- `logs/20260424T143927Z-build-module-stream-reg-lifecycle.log`

## Next Manual Runtime Use

Load the rebuilt module with an existing diagnostic profile that already sets
`dump_stream_regs=1`, for example:

```bash
sudo /home/cam/ov5647_driver_codex/scripts/run_manual_insmod_diag.sh full-delay-dump
sudo /home/cam/ov5647_driver_codex/scripts/run_manual_single_frame_rtcpu_trace.sh
```

Then compare in dmesg:

- `after_stream_on`
- `before_stream_off`
- `after_stream_off`

## Interpretation Target

If the key registers still look like active stream state at
`before_stream_off/after_stream_off`, that further supports:

- sensor-side stream intent remains alive,
- while Jetson still never observes usable CSI frame ingress.
