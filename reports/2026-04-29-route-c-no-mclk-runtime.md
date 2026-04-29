# 2026-04-29 Route-C No-MCLK Runtime

## Goal

Run a controlled route-C diagnostic where Jetson does not drive camera `MCLK`,
to see whether the failure class changes when `CAMx_MCLK` is removed from the
runtime path.

## Commands Run

```bash
sudo /home/cam/ov5647_driver_codex/scripts/run_manual_insmod_diag.sh full-delay-dump-no-mclk
sudo /home/cam/ov5647_driver_codex/scripts/run_manual_v4l2_direct_stream.sh
```

## Preconditions

- active boot profile: `ov5647-dev`
- active live route: route C
  - `cam_i2cmux/i2c@1/ov5647_c@36`
  - `serial_c`
  - `lane_polarity = 0`
  - `pix_clk_hz = 56004480`
  - `mclk_khz = 24000`

## Module Build Under Test

- module path:
  - `src/nv_ov5647/nv_ov5647.ko`
- `srcversion`:
  - `413B1FE812BFC66593A337E`

## Key Runtime Evidence

The driver did apply the new diagnostic path:

- `skip_mclk_enable=1`
- `ov5647_power_on: skip_mclk_enable=1, leaving MCLK undriven by Jetson`
- `ov5647_power_off: skip_mclk_enable=1, not disabling MCLK because it was never enabled`

Probe still succeeded:

- chip ID was still detected as `0x5647`
- `/dev/video0` appeared
- `VIDIOC_STREAMON returned 0 (Success)`

Capture result did not improve:

- `capture rc=124`
- raw output size `0 bytes`
- repeated:
  - `tegra-camrtc-capture-vi: uncorr_err: request timed out after 2500 ms`

Sensor-side lifecycle also stayed consistent with earlier runs:

- `after_stream_on`: sensor entered stream state
- `before_stream_off`: sensor still looked streaming
- `after_stream_off`: normal stop/LP11 state

## Practical Interpretation

This is a negative diagnostic for the specific hypothesis
“Jetson actively driving `MCLK` is the dominant reason capture fails”.

What this result means:

- removing Jetson-driven `MCLK` did not cause an earlier failure;
- removing Jetson-driven `MCLK` did not change the final failure class;
- the system still reached the same route-C zero-byte capture timeout.

This weakens the narrow runtime hypothesis that current Jetson-driven `MCLK`
alone is the main blocker.

It does **not** prove that the physical `CAMx_MCLK` pin is irrelevant in the
real hardware path. It only proves that, in the current measured software path,
skipping `camera_common_mclk_enable()` does not change the externally visible
failure signature.

## Artifacts

- `logs/20260429T121654Z-manual-insmod-full-delay-dump-no-mclk.log`
- `logs/20260429T121654Z-manual-insmod-full-delay-dump-no-mclk.modinfo.log`
- `logs/20260429T121654Z-manual-insmod-full-delay-dump-no-mclk.dmesg-tail.log`
- `logs/20260429T121700Z-manual-v4l2-direct-stream.log`
- `logs/20260429T121700Z-manual-v4l2-direct-stream-live-dmesg.log`
- `logs/20260429T121700Z-manual-v4l2-direct-stream-post-dmesg-tail.log`
- `artifacts/captures/20260429T121700Z/pre-v4l2-state.log`
- `artifacts/captures/20260429T121700Z/ov5647-640x480-bg10-count100.raw`

## Current Conclusion

The route-C no-MCLK experiment is another negative software-only check.

The strongest remaining branch is still physical CSI-path validation:

- cable orientation
- pin-family compatibility
- actual signal presence on `CSI CLK`, `D0`, `D1`
