# 2026-04-21 VGA HTS/VTS Runtime Timeout

## Summary

The rebuilt `nv_ov5647.ko` with explicit VGA HTS/VTS timing was runtime-tested by manual user commands. Module unload/load stayed stable, `/dev/video0` returned, and capture reached `VIDIOC_STREAMON`, but no frame data was delivered.

Result: this checkpoint does not fix the zero-byte capture problem.

## Context

- Target: Jetson Orin NX on CLB Developer Kit carrier.
- Active boot profile: previously confirmed `boot_profile=ov5647-dev`.
- Active logical camera route: `serial_b`, `port-index = 1`, `bus-width = <2>`, `lane_polarity = "6"`.
- Sensor: OV5647 on `i2c-9`, address `0x36`, chip ID `0x5647`.
- Current module source checkpoint before this test: `ae517a4 driver: program ov5647 vga hts vts timing`.

## User-Run Commands

The risky commands were run manually by the user to preserve Codex CLI context if the Jetson hung.

```bash
sudo /home/cam/ov5647_driver_codex/scripts/run_manual_rmmod_trace.sh
sudo /home/cam/ov5647_driver_codex/scripts/run_manual_insmod_diag.sh full-delay
sudo /home/cam/ov5647_driver_codex/scripts/run_manual_single_frame_trace.sh
```

## Observed Result

Manual capture output:

```text
VIDIOC_REQBUFS returned 0 (Success)
VIDIOC_QUERYBUF returned 0 (Success)
VIDIOC_QBUF returned 0 (Success)
VIDIOC_STREAMON returned 0 (Success)
capture rc=124
raw size=0 bytes
```

Raw artifact:

- `artifacts/captures/20260421T153826Z/ov5647-640x480-bg10.raw`
- size: `0` bytes

Kernel log summary:

- `ov5647_power_on` completed and logged `stream-stop LP-11 setup complete`;
- `ov5647_set_mode` applied mode `0`;
- `ov5647_start_streaming` returned success;
- VI then repeatedly logged `uncorr_err: request timed out after 2500 ms`;
- timeout cleanup called `ov5647_stop_streaming` and `ov5647_power_off`, both returned success.

## Logs

- `logs/20260421T153826Z-single-frame-trace.log`
- `logs/20260421T153826Z-stream-live-dmesg.log`
- `logs/20260421T153826Z-single-frame-post-dmesg-tail.log`
- `logs/20260421T153949Z-after-vga-hts-vts-capture-timeout-state.log`
- `logs/20260421T153949Z-after-vga-hts-vts-capture-timeout-dmesg.log`
- `logs/20260421T153949Z-vga-hts-vts-capture-timeout-script-log-summary.log`

## Interpretation

The sensor probe path, V4L2 registration, media graph registration, mode programming, LP-11 setup, and `STREAMON` callback path are all executing. The persistent VI timeout means the capture engine is still not receiving valid CSI frame data.

After explicit HTS/VTS programming failed to change the symptom, the next highest-value hypothesis is no valid CSI packet flow on the configured route. That may be caused by:

- wrong physical connector to `serial_b` / `port-index = 1` mapping;
- lane polarity or lane order mismatch;
- incomplete endpoint/DT route for the actual connector;
- remaining sensor mode-table difference, less likely than route mismatch but still possible.

## Next Smallest Safe Step

Do not run `insmod`, `rmmod`, capture, stream, or reboot from Codex.

Next safe work:

1. Inspect live DT and media graph read-only for all camera endpoints and route candidates.
2. Compare active overlay against available NVIDIA camera routes for this platform.
3. Decide whether the next experiment should be a minimal mode-table cleanup or an alternate DT route/connector overlay.

No reboot is required for this documentation checkpoint.
