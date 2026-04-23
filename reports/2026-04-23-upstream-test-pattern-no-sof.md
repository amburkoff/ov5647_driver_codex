# Upstream Test Pattern No-SOF

Date: 2026-04-23

## What Changed

- Loaded the corrected OV5647 module that uses upstream Linux test-pattern register `0x503d`.
- Ran one traced single-frame capture with OV5647 built-in color bars enabled.

## Commands Run

```bash
sudo /home/cam/ov5647_driver_codex/scripts/run_manual_insmod_diag.sh full-delay-dump-mclk24-testpat
sudo /home/cam/ov5647_driver_codex/scripts/run_manual_single_frame_rtcpu_trace.sh
```

## Artifacts

- `logs/20260423T105431Z-manual-insmod-full-delay-dump-mclk24-testpat.log`
- `logs/20260423T105431Z-manual-insmod-full-delay-dump-mclk24-testpat.dmesg-tail.log`
- `logs/20260423T105442Z-single-frame-rtcpu-live-dmesg.log`
- `logs/20260423T105442Z-single-frame-rtcpu-post-dmesg-tail.log`
- `logs/20260423T105442Z-single-frame-rtcpu-trace.log`
- `artifacts/traces/20260423T105442Z/`
- `artifacts/captures/20260423T105442Z/ov5647-640x480-bg10.raw`

## Passed

- Corrected module loaded successfully:
  - `srcversion=A0015C1CFA665DFD8D8A041`
  - `ov5647_test_pattern=1`
- Upstream-style test pattern is really active:
  - `0x503d = 0x80` after `set_mode`
  - `0x503d = 0x80` after `STREAMON`
- Sensor stream state remains coherent:
  - `0x0100 = 0x01`
  - output-enable registers restored
  - mode timing and MIPI control registers read back as expected

## Failed

- Single-frame capture timed out after 30 seconds.
- Raw file size is `0` bytes.
- VI reported repeated `uncorr_err: request timed out after 2500 ms`.
- RTCPU/NVCSI trace still showed no SOF/EOF and no receiver interrupt events.

## Interpretation

This is the strongest software-side result so far.

Because the sensor is now generating its own synthetic color-bar frames and the receiver still sees nothing:

- the blocker is no longer plausibly explained by optics, exposure, scene brightness, or live-image mode tuning;
- the dominant cause is now the physical CSI path:
  - cable / pinout mismatch
  - connector orientation
  - CLB carrier camera wiring mismatch relative to p3768 expectations
  - incompatibility of the native `JT-ZERO-V2.0` 22-pin Pi Zero-style module with the Jetson camera connector path

## Next Best Step

- Stop blind software tuning on the current hardware path.
- Prefer one of:
  - known-good Jetson-compatible camera plus cable
  - in-situ connector-orientation photos on the CLB carrier
  - proven remap/adapter specifically for Pi Zero-style 22-pin camera modules on Jetson

## Reboot Needed

- No.
