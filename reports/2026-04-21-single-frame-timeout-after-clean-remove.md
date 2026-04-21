# 2026-04-21 Single Frame Timeout After Clean Remove

## Context

- Runtime test was executed manually by the user.
- Codex did not run `insmod`, `rmmod`, capture, stream, or reboot.
- The loaded module was the normal full-probe path after the corrected remove lookup had already passed a normal `rmmod`.
- Active boot profile at session resume:
  - `boot_profile=ov5647-dev`
- Active module state before capture:
  - `register_i2c_driver=Y`
  - `allow_hw_probe=Y`
  - `skip_v4l2_register=N`
  - `skip_v4l2_unregister=N`
  - `split_v4l2_unregister=N`
  - `unload_marker_delay_ms=500`

## Manual Command

```text
sudo /home/cam/ov5647_driver_codex/scripts/run_manual_single_frame_trace.sh
```

## Result

The capture path reached `VIDIOC_STREAMON`, but no frame was delivered:

```text
VIDIOC_STREAMON returned 0 (Success)
capture rc=124
raw size=0 bytes path=/home/cam/ov5647_driver_codex/artifacts/captures/20260421T151642Z/ov5647-640x480-bg10.raw
```

Kernel trace shows the driver power and streaming lifecycle returned cleanly:

```text
ov5647_power_on: exit success
ov5647_set_mode: mode applied, sensor remains in standby
ov5647_start_streaming: enter
ov5647_start_streaming: exit success
tegra-camrtc-capture-vi tegra-capture-vi: uncorr_err: request timed out after 2500 ms
ov5647_stop_streaming: exit success
ov5647_power_off: exit success
```

## Logs

- `logs/20260421T151526Z-manual-insmod-full-delay.log`
- `logs/20260421T151558Z-before-capture-full-delay-insmod-state.log`
- `logs/20260421T151559Z-before-capture-v4l2-list-devices.log`
- `logs/20260421T151559Z-before-capture-v4l2-all.log`
- `logs/20260421T151559Z-before-capture-v4l2-formats.log`
- `logs/20260421T151559Z-before-capture-media-ctl-p.log`
- `logs/20260421T151559Z-dmesg-before-capture-full-delay.log`
- `logs/20260421T151642Z-single-frame-trace.log`
- `logs/20260421T151642Z-stream-live-dmesg.log`
- `logs/20260421T151642Z-single-frame-post-dmesg-tail.log`
- `logs/20260421T151757Z-single-frame-151642-analysis.log`
- `logs/20260421T151757Z-dmesg-after-single-frame-151642.log`
- `logs/20260421T151757Z-state-after-single-frame-151642.log`
- `artifacts/captures/20260421T151642Z/ov5647-640x480-bg10.raw`

## Interpretation

This is no longer a probe/remove problem. The current failure boundary is:

- `/dev/video0` exists;
- media graph is linked;
- V4L2 format is `BG10 640x480`;
- `STREAMON` returns success;
- VI receives no completed frame and times out.

The next likely defect is in the minimal sensor mode or CSI timing. A direct comparison against upstream Linux OV5647 shows the local 640x480 table differs from upstream in the VGA mode setup, including `0x3821` and additional local-only VGA table writes.

## Next Step

Prepare one source-only change to align the 640x480 10-bit mode table with upstream Linux OV5647, rebuild, commit, and ask the user to manually run the next unload/load/capture sequence one command at a time.
