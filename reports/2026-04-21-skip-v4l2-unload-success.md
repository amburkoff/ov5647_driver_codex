# 2026-04-21 Skip-V4L2 Unload Success

## What Happened

- the user manually loaded the module with:
  - `register_i2c_driver=1 allow_hw_probe=1 skip_v4l2_register=1`
- the user then manually ran:
  - `sudo /home/cam/ov5647_driver_codex/scripts/run_manual_rmmod_trace.sh`
- the unload helper returned:
  - `rmmod rc=0`

## Collected Artifacts

- `logs/20260421T085230Z-rmmod-trace.log`
- `logs/20260421T085230Z-rmmod-live-dmesg.log`
- `logs/20260421T085230Z-rmmod-pre-dmesg-tail.log`

## Findings

- `skip_v4l2_register=1` probe completed chip-ID detection successfully:
  - chip ID `0x5647`;
  - no V4L2 subdev registration;
  - no `/dev/video0` path expected from this isolated mode.
- unload reached and returned from:
  - `module_exit`;
  - `i2c_del_driver`;
  - `ov5647_remove`;
  - `tegracam_device_unregister`.
- unload skipped:
  - `tegracam_v4l2subdev_unregister`.
- unload returned successfully:
  - `rmmod rc=0`

## Remaining Warning

- `tegracam_device_unregister()` still emits:
  - `WARNING: CPU: ... at drivers/base/devres.c:1069 devm_kfree`
- this warning is not a hang in the isolated mode, but it remains a robustness issue;
- the same warning was seen earlier on failed-probe unwind paths.

## Interpretation

- the hard unload hang is not caused by basic I2C driver removal;
- the hard unload hang is not caused by chip-ID probe;
- the hard unload hang is not caused by `tegracam_device_unregister()` alone;
- the next likely boundary is V4L2 subdev/media graph registration and unregister lifetime.

## Next Best Step

Do not repeat full streaming yet.

The safest next code-side work has been applied:

- remove no longer calls `ov5647_power_off()` directly;
- remove now lets the tegracam/V4L2 unregister path manage device lifetime;
- remove destroys the local mutex after framework unregister.

Next manual test:

- load the module with full V4L2 registration;
- run the `dmesg -W` unload helper once;
- if it still hangs, the live trace should now identify whether the last visible marker is before or after `tegracam_v4l2subdev_unregister()`.
