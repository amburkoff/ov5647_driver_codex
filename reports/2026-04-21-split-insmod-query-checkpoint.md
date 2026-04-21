# 2026-04-21 Split Insmod Query Checkpoint

## Context

- user manually ran:
  - `sudo /home/cam/ov5647_driver_codex/scripts/run_manual_insmod_diag.sh split-unregister`
- user reported:
  - `insmod ok`
- Codex did not run `rmmod`, streaming, capture, or reboot for this checkpoint.

## Loaded Module State

- `nv_ov5647` is loaded;
- module refcount is `0`;
- active parameters:
  - `register_i2c_driver=Y`
  - `allow_hw_probe=Y`
  - `skip_v4l2_register=N`
  - `skip_v4l2_unregister=N`
  - `split_v4l2_unregister=Y`
  - `unload_marker_delay_ms=500`

Logs:

- `logs/20260421T102127Z-after-split-insmod-module-state.log`
- `logs/20260421T102127Z-after-split-insmod-modinfo.log`
- `logs/20260421T102127Z-after-split-insmod-dmesg-tail.log`

## Probe Result

Kernel log confirms:

- module init includes `split_v4l2_unregister=1`;
- probe entered on `nv_ov5647 9-0036`;
- DT parse found:
  - `mclk=extperiph1`
  - `reset_gpio=-1`
  - `pwdn_gpio=397`
  - `avdd=vana`
  - `dvdd=vdig`
  - `iovdd=vif`
- chip ID read succeeded:
  - `0x5647`
- `tegra-capture-vi` bound the subdev;
- probe exited successfully.

## Query-Level V4L2 / Media Checks

No stream was started.

Passed query checks:

- `v4l2-ctl --list-devices`;
- `v4l2-ctl -d /dev/video0 --all`;
- `v4l2-ctl -d /dev/video0 --list-formats-ext`;
- `media-ctl -p`.

Result:

- `/dev/video0` exists;
- format is `BG10`;
- size is `640x480`;
- `Size Image = 614400`;
- media graph is linked:
  - `nv_ov5647 9-0036` -> `nvcsi` -> `vi-output`;
- sensor subdev reports:
  - `SBGGR10_1X10/640x480@1/30`.

Logs:

- `logs/20260421T102141Z-after-split-insmod-v4l2-list-devices.log`
- `logs/20260421T102141Z-after-split-insmod-v4l2-all.log`
- `logs/20260421T102141Z-after-split-insmod-v4l2-formats.log`
- `logs/20260421T102141Z-after-split-insmod-media-ctl-p.log`

## Runtime Status

- module is currently loaded;
- no capture has been attempted after the output-enable fix;
- no unload has been attempted after the split-unregister load.

## Next Best Step

Run exactly one manual single-frame capture and report whether it returns, hangs, or creates a non-empty raw file.
