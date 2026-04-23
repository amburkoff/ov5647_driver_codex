# Route-A Non-Continuous Clock Timeout

Date: 2026-04-23

## Context

- Camera/ribbon: alternate OV5647 on Jetson `cam0`, ribbon marked `Frank-s15-v1.0`.
- Active boot profile: `boot_profile=ov5647-dev`.
- Active live DT route: route A, `ov5647_a@36`, `serial_b`, `port-index = 1`, `lane_polarity = 6`.
- Driver source variant: mainline VGA timing bit diagnostic, `0x3821 = 0x03`.
- Manual load profile: `full-delay-dump-mclk24`.

## Result

- Capture timestamp: `20260423T080309Z`.
- Capture command reached `VIDIOC_STREAMON returned 0`.
- Capture returned `rc=124`.
- Raw output: `artifacts/captures/20260423T080309Z/ov5647-640x480-bg10.raw`.
- Raw size: `0 bytes`.
- RTCPU/NVCSI trace directory: `artifacts/traces/20260423T080309Z`.
- Dmesg log: `logs/20260423T080309Z-single-frame-rtcpu-live-dmesg.log`.

## Evidence

- Module parameters confirmed `continuous_mipi_clock=N` and `mclk_override_hz=24000000`.
- MCLK enabled at `24000000`.
- Stream state readback after stream-on:
  - `0x0100 = 0x01`;
  - `0x3000 = 0x0f`;
  - `0x3001 = 0xff`;
  - `0x3002 = 0xe4`;
  - `0x3821 = 0x03`;
  - `0x4800 = 0x34`.
- VI reported repeated `uncorr_err: request timed out after 2500 ms`.
- RTCPU trace events were enabled but contained no runtime SOF/EOF/NVCSI/vinotify event.

## Interpretation

This removes the known mismatch between route-A DT `discontinuous_clk = "yes"` and the previous sensor-side continuous-clock diagnostic. The no-SOF symptom remains.

The next bounded software experiment is route A with `lane_polarity = "0"` instead of the p3768 reference value `6`, while keeping I2C, `serial_b`, `port-index = 1`, lane count, MCLK, mode table, and manual module profile unchanged.

If route-A lane polarity `0` still produces no SOF, the dominant blocker remains CLB/makerobo physical CSI routing or Raspberry Pi Zero-style camera/cable pin compatibility rather than OV5647 stream register state.
