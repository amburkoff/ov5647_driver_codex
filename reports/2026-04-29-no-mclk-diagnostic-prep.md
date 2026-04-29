# 2026-04-29 No-MCLK Diagnostic Prep

## Goal

Prepare a controlled manual runtime test where Jetson does not drive camera
`MCLK`, to check whether the current no-frame signature changes at all when the
`CAMx_MCLK` path is removed from the equation.

## Changes

- added module parameter:
  - `skip_mclk_enable=1`
- this parameter skips:
  - `camera_common_mclk_enable()`
  - `camera_common_mclk_disable()`
- added manual insmod profile:
  - `full-delay-dump-no-mclk`

## Files Changed

- `src/nv_ov5647/nv_ov5647.c`
- `scripts/run_manual_insmod_diag.sh`

## Build Result

The module was rebuilt successfully:

- build artifacts:
  - `artifacts/build/20260429T121109Z`

## Intended Manual Test

Run after ensuring `nv_ov5647` is not already loaded:

```bash
sudo /home/cam/ov5647_driver_codex/scripts/run_manual_insmod_diag.sh full-delay-dump-no-mclk
sudo /home/cam/ov5647_driver_codex/scripts/run_manual_v4l2_direct_stream.sh
```

Optional, if the module is already loaded:

```bash
sudo /home/cam/ov5647_driver_codex/scripts/run_manual_rmmod_trace.sh
```

## What To Look For

- whether probe still succeeds without Jetson-driven `MCLK`
- whether `/dev/video0` still appears
- whether `VIDIOC_STREAMON` still returns success
- whether the failure mode changes:
  - earlier probe failure
  - earlier stream failure
  - same timeout / zero-byte raw output

## Interpretation

This is a narrow diagnostic only.

- If probe fails much earlier, that is consistent with OV5647 actually needing
  the current Jetson-driven `MCLK` path.
- If behavior stays identical, then the current `MCLK` drive is less likely to
  be the dominant explanation for the no-SOF failure.
