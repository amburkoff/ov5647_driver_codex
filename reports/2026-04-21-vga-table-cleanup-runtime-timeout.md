# 2026-04-21 VGA Table Cleanup Runtime Timeout

## Summary

The VGA table cleanup build was manually runtime-tested. The correct rebuilt module was loaded, `VIDIOC_STREAMON` returned success, but the capture still timed out and produced a zero-byte raw file.

Result: removing local-only VGA writes `0x5002` and `0x4837` did not restore CSI frame delivery.

## Module Identity

- built module `srcversion`: `2F4050CDED69B8A5FF0C49F`
- loaded module `srcversion`: `2F4050CDED69B8A5FF0C49F`
- module parameters:
  - `register_i2c_driver=Y`
  - `allow_hw_probe=Y`
  - `skip_v4l2_register=N`
  - `skip_v4l2_unregister=N`
  - `split_v4l2_unregister=N`
  - `unload_marker_delay_ms=500`

## User-Run Commands

The user ran the risky commands manually.

```bash
sudo /home/cam/ov5647_driver_codex/scripts/run_manual_rmmod_trace.sh
sudo /home/cam/ov5647_driver_codex/scripts/run_manual_insmod_diag.sh full-delay
sudo /home/cam/ov5647_driver_codex/scripts/run_manual_single_frame_trace.sh
```

## Capture Result

```text
VIDIOC_REQBUFS returned 0 (Success)
VIDIOC_QUERYBUF returned 0 (Success)
VIDIOC_QBUF returned 0 (Success)
VIDIOC_STREAMON returned 0 (Success)
capture rc=124
raw size=0 bytes
```

Raw artifact:

- `artifacts/captures/20260421T155031Z/ov5647-640x480-bg10.raw`
- size: `0` bytes

Kernel log summary:

- `rmmod` completed cleanly before the load;
- full-delay `insmod` completed cleanly;
- probe read chip ID `0x5647`;
- `ov5647_power_on` logged `stream-stop LP-11 setup complete`;
- `ov5647_set_mode` and `ov5647_start_streaming` returned success;
- VI logged repeated `uncorr_err: request timed out after 2500 ms`;
- timeout cleanup ran `ov5647_stop_streaming` and `ov5647_power_off`.

## Logs

- `logs/20260421T155010Z-rmmod-trace.log`
- `logs/20260421T155010Z-rmmod-live-dmesg.log`
- `logs/20260421T155023Z-manual-insmod-full-delay.log`
- `logs/20260421T155023Z-manual-insmod-full-delay.dmesg-tail.log`
- `logs/20260421T155031Z-single-frame-trace.log`
- `logs/20260421T155031Z-stream-live-dmesg.log`
- `logs/20260421T155031Z-single-frame-post-dmesg-tail.log`
- `logs/20260421T155141Z-after-vga-cleanup-capture-timeout-state.log`
- `logs/20260421T155141Z-vga-cleanup-capture-timeout-dmesg-tail-summary.log`

## Interpretation

At this point the following route-A source-side fixes have all failed to produce frame data:

- output-enable handling;
- `set_mode()` standby / `start_streaming()` separation;
- LP-11 stream-stop setup during power-on;
- explicit VGA HTS/VTS timing;
- VGA table cleanup against upstream/Raspberry Pi references.

The next best single-variable experiment is an alternate route-C overlay candidate. This tests the second physical CSI connector path using NVIDIA p3768 route-C conventions while keeping the driver source unchanged.

No reboot was requested for this report.
