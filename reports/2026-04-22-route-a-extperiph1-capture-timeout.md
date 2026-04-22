# Route-A Corrected-MCLK Capture Timeout

Date: 2026-04-22

## Context

- Target: Jetson Orin NX on CLB Developer Kit / makerobo partner board.
- Boot profile: `boot_profile=ov5647-dev`.
- Active overlay: `/boot/ov5647-p3768-port-a-extperiph1.dtbo`.
- Live DT route: `cam_i2cmux/i2c@0/ov5647_a@36`, `serial_b`, endpoint `port-index = 1`, `bus-width = 2`, `lane_polarity = "6"`.
- Clock binding: `TEGRA234_CLK_EXTPERIPH1` / BPMP clock ID `0x24`.

## Command Run Manually

The user ran:

```bash
sudo /home/cam/ov5647_driver_codex/scripts/run_manual_single_frame_rtcpu_trace.sh
```

## Result

- Timestamp: `20260422T140936Z`.
- `VIDIOC_STREAMON returned 0 (Success)`.
- Capture returned `rc=124`.
- Raw file: `artifacts/captures/20260422T140936Z/ov5647-640x480-bg10.raw`.
- Raw size: `0 bytes`.
- Dmesg log: `logs/20260422T140936Z-single-frame-rtcpu-live-dmesg.log`.
- RTCPU/NVCSI trace dir: `artifacts/traces/20260422T140936Z`.
- Evidence summary log: `logs/20260422T142000Z-route-a-capture-timeout-evidence.log`.

## Kernel And Trace Evidence

- Driver stream-on readback was internally consistent:
  - `ov5647_power_on: mclk enabled rate=24000000`;
  - `0x0100 = 0x01`;
  - `0x3000 = 0x0f`, `0x3001 = 0xff`, `0x3002 = 0xe4`;
  - `0x4800 = 0x04` with `continuous_mipi_clock=1`.
- VI reported repeated `uncorr_err: request timed out after 2500 ms`.
- Trace events were enabled for VI, RTCPU, NVCSI, and capture event points.
- Trace did not contain runtime `vi_frame_begin`, `vi_frame_end`, `rtcpu_nvcsi_intr`, `rtcpu_vinotify_error`, `capture_event_sof`, `capture_event_eof`, or `capture_event_error`.

## Interpretation

Route A and route C have both now been tested after fixing the BPMP clock ID to `TEGRA234_CLK_EXTPERIPH1`. Both routes probe, both create `/dev/video0`, and both reach `VIDIOC_STREAMON`, but neither route produces observable CSI SOF at NVCSI/VI.

The remaining leading hypothesis is physical CLB/makerobo CSI path incompatibility or mismatch: connector routing, FFC contact orientation, adaptor/pinout, Raspberry Pi-style `JT-ZERO-V2.0 YH` module compatibility, or lane wiring/polarity not represented by the NVIDIA p3768 reference overlays.

## Next Step

Do not continue blind stream-register tuning. The next smallest safe step is physical CSI-path validation:

- record carrier connector labels and cable orientation;
- photograph both camera module sides and the full FFC/adaptor path;
- verify the pinout path between the CLB 22-pin connector and the Raspberry Pi-style OV5647 module;
- if available, test a known-good Jetson-compatible camera/cable kit with a stock NVIDIA overlay to separate carrier/cable issues from the custom OV5647 driver.
