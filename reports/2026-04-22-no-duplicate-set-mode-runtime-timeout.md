# 2026-04-22 No Duplicate Set Mode Runtime Timeout

## Summary

The no-duplicate-set-mode module was runtime-tested on the route-C dev overlay. The intended code path executed, but single-frame capture still timed out with no raw data.

Result: removing the duplicate `ov5647_set_mode()` call from `ov5647_start_streaming()` did not fix frame delivery.

## User-Run Commands

The risky kernel operations were run manually by the user:

```bash
sudo /home/cam/ov5647_driver_codex/scripts/run_manual_rmmod_trace.sh
sudo /home/cam/ov5647_driver_codex/scripts/run_manual_insmod_diag.sh full-delay
sudo /home/cam/ov5647_driver_codex/scripts/run_manual_single_frame_trace.sh
```

## Runtime Identity

- boot profile: `ov5647-dev`;
- active route: route C;
- loaded module `srcversion`: `E9CE1D1EF58B852F6484431`;
- built module `srcversion`: `E9CE1D1EF58B852F6484431`;
- module parameters:
  - `register_i2c_driver=Y`;
  - `allow_hw_probe=Y`;
  - `skip_v4l2_register=N`;
  - `skip_v4l2_unregister=N`;
  - `split_v4l2_unregister=N`;
  - `unload_marker_delay_ms=500`.

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

- `artifacts/captures/20260422T080757Z/ov5647-640x480-bg10.raw`
- size: `0` bytes

## Kernel Log Evidence

The new source marker executed:

```text
ov5647_start_streaming: using mode already applied by tegracam set_mode
```

The capture still timed out:

```text
tegra-camrtc-capture-vi tegra-capture-vi: uncorr_err: request timed out after 2500 ms
```

Driver cleanup still returned:

- `ov5647_stop_streaming: exit success`;
- `ov5647_power_off: exit success`.

## Interpretation

The previous duplicate mode programming was a real driver defect because it re-applied the common table and software reset immediately before stream enable. However, this runtime test proves it was not the only blocker for frame delivery.

Current evidence:

- route A and route C both probe successfully;
- both routes expose `/dev/video0`;
- both routes reach `VIDIOC_STREAMON`;
- neither route delivers a frame;
- latest route-C test used the corrected no-duplicate stream-start path.

The next safest step is diagnostic readback around stream start, not another blind timing tweak. The driver should dump key OV5647 registers after mode programming and after stream enable so the next manual capture can confirm whether the sensor actually remains configured and leaves standby.

## Logs

- `logs/20260422T080729Z-rmmod-trace.log`
- `logs/20260422T080740Z-manual-insmod-full-delay.log`
- `logs/20260422T080740Z-manual-insmod-full-delay.dmesg-tail.log`
- `logs/20260422T080740Z-manual-insmod-full-delay.modinfo.log`
- `logs/20260422T080757Z-single-frame-trace.log`
- `logs/20260422T080757Z-stream-live-dmesg.log`
- `logs/20260422T080757Z-single-frame-post-dmesg-tail.log`
- `logs/20260422T080903Z-after-no-duplicate-set-mode-capture-state.log`
- `logs/20260422T080903Z-no-duplicate-set-mode-capture-live-dmesg-summary.log`
- `logs/20260422T080903Z-no-duplicate-set-mode-capture-post-dmesg-summary.log`
- `logs/20260422T080903Z-no-duplicate-set-mode-reload-log-summary.log`

## Next Step

Prepare a diagnostic-only source change:

- add a gated register readback dump around `set_mode()` and `start_streaming()`;
- include `0x0100`, `0x3000`, `0x3001`, `0x3002`, `0x300d`, `0x4202`, `0x4800`, `0x4814`, `0x380c`-`0x380f`, `0x3820`, `0x3821`, and selected PLL registers;
- rebuild only;
- ask the user to manually run reload and one capture.

No reboot is needed.
