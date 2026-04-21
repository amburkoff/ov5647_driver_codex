# 2026-04-21 rmmod Hang Clientdata Root Cause

## Context

- User manually loaded the rebuilt module with:
  - `sudo /home/cam/ov5647_driver_codex/scripts/run_manual_insmod_diag.sh split-unregister`
- Probe succeeded.
- User then manually ran the traced unload and reported a hard hang.
- Recovery required power-cycle.

Codex did not run `insmod`, `rmmod`, capture, stream, or reboot.

## Post-Recovery State

- Active boot profile:
  - `boot_profile=ov5647-dev`
- `nv_ov5647` is not loaded after recovery.
- `/sys/fs/pstore` is empty.
- `last -x` records the previous session as `crash`.

Logs:

- `logs/20260421T145809Z-post-powercycle-after-rmmod-hang-state.log`
- `logs/20260421T145809Z-pstore-after-powercycle-rmmod-hang.log`
- `logs/20260421T145809Z-latest-rmmod-logs-after-powercycle.log`

## Latest Hang Boundary

Primary live log:

- `logs/20260421T145443Z-rmmod-live-dmesg.log`

Last lines before hang:

```text
nv_ov5647: module exit enter driver_registered=1
nv_ov5647: before i2c_del_driver
nv_ov5647 9-0036: ov5647_remove: enter
nv_ov5647 9-0036: ov5647_remove: state tc_dev=... priv=... tc_dev->priv=... s_data=... s_data->priv=0000000000000000 v4l2_registered=0 ...
nv_ov5647 9-0036: ov5647_remove: V4L2 registration flag is not set, but full probe path requires unregister; forcing V4L2 unregister before device cleanup
nv_ov5647 9-0036: ov5647_remove: before tegracam_v4l2subdev_unregister
nv_ov5647 9-0036: ov5647_remove: split_v4l2_unregister=1; diagnostic path, using inline unregister phases
(NULL device *): ov5647_split_v4l2subdev_unregister: before v4l2_ctrl_handler_free
```

## Root Cause

`ov5647_remove()` was incorrectly using:

```c
i2c_get_clientdata(client)
```

as if it still returned `struct tegracam_device *`.

That is invalid after `tegracam_v4l2subdev_register()` because the framework path calls `v4l2_i2c_subdev_init()`, which makes the I2C clientdata point at the V4L2 subdev.

Result:

- `ov5647_remove()` interpreted a `struct v4l2_subdev *` as `struct tegracam_device *`;
- remove-time state dump showed impossible state:
  - `s_data->priv=NULL`;
  - `v4l2_registered=0`;
  - `(NULL device *)` inside split unregister;
- cleanup then operated on corrupted pointers and hung during the V4L2 unregister path.

This also explains why prior forced-unregister logic moved the hang instead of fixing it.

## Source Fix Prepared

`ov5647_remove()` now follows the NVIDIA sample sensor pattern:

- get `struct camera_common_data *` from `to_camera_common_data(&client->dev)`;
- get `struct ov5647 *` from `s_data->priv`;
- get `struct tegracam_device *` from `priv->tc_dev`;
- refuse unsafe remove if either `s_data` or `priv` is missing.

Probe was also aligned with NVIDIA sample style:

- call `tegracam_set_privdata(tc_dev, priv)` after `tegracam_device_register()`;
- call it again after successful V4L2 subdev registration;
- log `tc_dev`, `tc_dev->priv`, `s_data`, `s_data->priv`, and `v4l2_registered`.

## Validation

Safe validation only:

- `git diff --check` passed;
- module build passed;
- `modinfo` saved;
- built `.ko` contains the new remove/probe state markers;
- no runtime load/unload was run by Codex.

Logs:

- `logs/20260421T145951Z-build-remove-clientdata-rootcause.log`
- `logs/20260421T150003Z-modinfo-remove-clientdata-rootcause.log`
- `logs/20260421T150003Z-strings-remove-clientdata-rootcause.log`
- `logs/20260421T150003Z-post-build-remove-clientdata-no-runtime-load-state.log`

## Next Smallest Manual Test

Use the same conservative split-unregister profile once:

```bash
sudo /home/cam/ov5647_driver_codex/scripts/run_manual_insmod_diag.sh split-unregister
```

If it reports `insmod rc=0`, run exactly:

```bash
sudo env RMMOD_SYSRQ_DELAY_SEC=10 /home/cam/ov5647_driver_codex/scripts/run_manual_rmmod_trace.sh
```

Expected new evidence:

- `s_data->priv` should be non-NULL;
- `tc_dev->dev` should be non-NULL;
- `v4l2_registered` should be `1`;
- the split unregister should pass `v4l2_ctrl_handler_free` or provide a real next boundary.
