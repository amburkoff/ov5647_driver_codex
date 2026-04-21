# 2026-04-21 Single Frame Timeout After Output Enable Fix

## Context

- rebuilt module was loaded with:
  - `split_v4l2_unregister=1`
  - `unload_marker_delay_ms=500`
- query-only V4L2/media checks passed before capture;
- user manually ran:
  - `sudo /home/cam/ov5647_driver_codex/scripts/run_manual_single_frame_trace.sh`

## Result

- `VIDIOC_STREAMON` returned success;
- capture timed out by userspace helper after 30 seconds:
  - `capture rc=124`
- raw output file exists but is empty:
  - `artifacts/captures/20260421T102646Z/ov5647-640x480-bg10.raw`
  - size `0` bytes
- kernel remained alive;
- after the timeout, the driver ran:
  - `ov5647_stop_streaming`
  - `ov5647_power_off`
- module remains loaded with refcount `0`;
- no userspace holder was found for media/video/subdev nodes.

## Kernel Evidence

Stream path:

- `ov5647_power_on: exit success`
- `ov5647_set_mode: applying mode=0 name=640x480-10bpp-30fps 640x480`
- `ov5647_start_streaming: enter`
- `ov5647_set_mode: applying mode=0 name=640x480-10bpp-30fps 640x480`
- `ov5647_start_streaming: exit success`

VI failure:

- repeated `uncorr_err: request timed out after 2500 ms`

Cleanup:

- `ov5647_stop_streaming: exit success`
- `ov5647_power_off: exit success`

Logs:

- `logs/20260421T102646Z-single-frame-trace.log`
- `logs/20260421T102646Z-stream-live-dmesg.log`
- `logs/20260421T102646Z-single-frame-post-dmesg-tail.log`
- `logs/20260421T102807Z-after-timeout-capture-module-holders.log`
- `logs/20260421T102807Z-after-timeout-capture-dmesg-tail.log`
- `logs/20260421T102807Z-capture-102646-analysis.log`

## Root-Cause Hypothesis

The output-enable fix alone is not sufficient.

Important new observation:

- NVIDIA r36.5 `tegracam_v4l2.c` calls sensor `set_mode()` before `start_streaming()`;
- NVIDIA sample drivers (`nv_imx219.c`, `nv_imx185.c`) keep `set_mode()` limited to mode table programming;
- start of sensor output is done from `start_streaming()`.

Current OV5647 code still writes `OV5647_REG_MODE_SELECT = STREAMING` inside `ov5647_set_mode()`. That can start MIPI output before VI is fully in the stream-start phase. The next code change should remove streaming enable from `set_mode()` and leave `0x0100=1` only in `ov5647_start_streaming()`.

## Next Step

Prepare a source-only fix:

- keep `ov5647_set_mode()` in standby after writing common/mode registers;
- start streaming only in `ov5647_start_streaming()`;
- build and commit;
- runtime validation will require a future safe module reload.
