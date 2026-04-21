# 2026-04-21 rmmod Hang Before Device Unregister

## Context

- User manually ran:
  - `sudo env RMMOD_SYSRQ_DELAY_SEC=10 /home/cam/ov5647_driver_codex/scripts/run_manual_rmmod_trace.sh`
- The Jetson hung during `rmmod nv_ov5647`.
- After recovery, the system is reachable again with:
  - `boot_profile=ov5647-dev`
  - `nv_ov5647` not loaded
  - empty `/sys/fs/pstore`
- No risky runtime command was run by Codex after the hang.

## Evidence

Primary logs:

- `logs/20260421T140616Z-rmmod-trace.log`
- `logs/20260421T140616Z-rmmod-live-dmesg.log`
- `logs/20260421T140616Z-rmmod-pre-dmesg-tail.log`
- `logs/20260421T141019Z-after-rmmod-hang-reachability.log`
- `logs/20260421T141038Z-timeline-after-rmmod-hang.log`
- `logs/20260421T141301Z-sudo-pstore-after-latest-hang.log`

Important live-dmesg boundary:

```text
nv_ov5647: module exit enter driver_registered=1
nv_ov5647: before i2c_del_driver
nv_ov5647 9-0036: ov5647_remove: enter
nv_ov5647 9-0036: ov5647_remove: v4l2 subdev was not registered, skipping unregister
nv_ov5647 9-0036: ov5647_remove: before tegracam_device_unregister
```

The trace never reached:

- `after tegracam_device_unregister`
- `rmmod rc=...`

## Interpretation

This hang is no longer only "before module exit" or "somewhere in remove".
It is now localized to the path after `ov5647_remove()` skipped V4L2/media unregister and before or inside `tegracam_device_unregister()`.

That skip is logically unsafe for a full successful probe path:

- `skip_v4l2_register=0` was used for the loaded diagnostic module;
- `/dev/video0` and the media graph existed before unload;
- therefore V4L2/media state should have been unregistered before device cleanup.

The private `priv->v4l2_registered` flag was not reliable enough as the sole remove-time source of truth.

## Change Prepared

Source-only fix:

- `ov5647_remove()` now logs `tc_dev`, `priv`, `tc_dev->priv`, `s_data`, `s_data->priv`, and all V4L2 diagnostic flags;
- if `s_data` exists and the module was not loaded with `skip_v4l2_register=1`, remove forces V4L2 unregister before `tegracam_device_unregister()`;
- if the private flag says otherwise, remove emits a warning instead of silently skipping unregister.

Validation performed by Codex:

- source diff saved;
- `git diff --check` passed;
- module build passed;
- `modinfo` saved;
- marker strings verified in the built `.ko`;
- no `insmod`, `rmmod`, capture, stream, or reboot was run by Codex.

Validation logs:

- `logs/20260421T141419Z-build-force-v4l2-unregister.log`
- `logs/20260421T141435Z-modinfo-force-v4l2-unregister.log`
- `logs/20260421T141435Z-strings-force-v4l2-unregister.log`
- `logs/20260421T141435Z-post-build-no-runtime-load-state.log`

## Next Smallest Manual Test

The next risky runtime test should remain manual.

Recommended sequence:

```bash
sudo /home/cam/ov5647_driver_codex/scripts/run_manual_insmod_diag.sh split-unregister
```

If that reports `insmod ok`, run exactly:

```bash
sudo env RMMOD_SYSRQ_DELAY_SEC=10 /home/cam/ov5647_driver_codex/scripts/run_manual_rmmod_trace.sh
```

Expected useful result:

- either `rmmod rc=0`, proving the forced unregister path avoided the hang;
- or a newer live-dmesg boundary showing the exact V4L2 unregister phase that blocks.
