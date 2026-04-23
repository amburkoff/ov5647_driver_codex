# Route-A Lane-Polarity-0 Runtime Timeout

Date: 2026-04-23

## What Changed

- Kept the rebooted `ov5647-dev` profile with `/boot/ov5647-p3768-port-a-lanepol0.dtbo`.
- Ran the first manual runtime on the live `lane_polarity = 0` route-A DT.
- Cross-checked carrier mapping against public `NXCLB` / CLB FCC user-manual evidence.

## Commands Run

```bash
sudo /home/cam/ov5647_driver_codex/scripts/run_manual_insmod_diag.sh full-delay-dump-mclk24
sudo /home/cam/ov5647_driver_codex/scripts/run_manual_single_frame_rtcpu_trace.sh
```

## Logs And Artifacts

- `logs/20260423T085315Z-manual-insmod-full-delay-dump-mclk24.log`
- `logs/20260423T085315Z-manual-insmod-full-delay-dump-mclk24.dmesg-tail.log`
- `logs/20260423T085323Z-single-frame-rtcpu-live-dmesg.log`
- `logs/20260423T085323Z-single-frame-rtcpu-post-dmesg-tail.log`
- `logs/20260423T085323Z-single-frame-rtcpu-trace.log`
- `logs/20260423T090300Z-analyze-lanepol0-insmod.log`
- `logs/20260423T090300Z-analyze-lanepol0-capture.log`
- `logs/20260423T090300Z-analyze-lanepol0-rtcpu.log`
- `artifacts/captures/20260423T085323Z/ov5647-640x480-bg10.raw`
- `artifacts/traces/20260423T085323Z/`
- `artifacts/camera-route-state/20260423T085021Z/live-dt-ov5647-route-summary.log`

## Passed

- `boot_profile=ov5647-dev` remained active after reboot.
- Live DT confirms:
  - `cam_i2cmux/i2c@0/ov5647_a@36`
  - `serial_b`
  - `port-index = 1`
  - `bus-width = 2`
  - `lane_polarity = 0`
  - `discontinuous_clk = yes`
  - `clocks = <&bpmp 0x24>`
- Manual `insmod` succeeded with:
  - chip ID `0x5647`
  - MCLK `24000000` Hz
  - `/dev/video0` present
  - media graph linked
- `VIDIOC_STREAMON` returned success.
- Stream-state register readback stayed internally consistent after `set_mode()` and after `STREAMON`.

## Failed

- Single-frame raw capture timed out after 30 seconds.
- Raw output size is `0` bytes.
- VI logged repeated `uncorr_err: request timed out after 2500 ms`.
- RTCPU/NVCSI trace again showed no SOF/EOF, no NVCSI interrupt, and no vinotify error.

## Findings

- Changing only route-A `lane_polarity` from `6` to `0` did not change the no-SOF behavior.
- The current blocker is no longer explained by basic probe, media registration, output-enable state, `0x3821`, `0x4800`, or corrected `extperiph1` MCLK.
- Public `NXCLB` documentation now supports the assumption that the CLB/makerobo carrier exposes devkit-style `J20`/`J21` camera connectors with the same I2C mux split as NVIDIA `p3768`.
- That still does not validate the physical FFC orientation or the exact pinout presented by the Raspberry Pi-market OV5647 modules and cables.

## Root-Cause Hypothesis

Highest-probability blocker is now the physical CSI path:

- wrong physical connector to logical route mapping;
- wrong 22-pin FFC orientation/contact-side assumption;
- wrong cable pinout family for the OV5647 module;
- CLB carrier camera path differs electrically from the software-visible p3768 model even though the mux split looks devkit-like.

## Next Smallest Step

- Stop blind route/lane permutations.
- Prefer one hardware-validation step that can falsify the physical-path hypothesis:
  - document the actual CLB connector labels and cable orientation with photos, or
  - test a known-good Jetson-compatible IMX219/IMX477 kit on the same connector with the stock NVIDIA overlay, or
  - derive the exact camera connector wiring from CLB/NXCLB documentation if a schematic becomes available.

## Reboot Needed

- No.

## Default Boot Profile

- `ov5647-dev`
