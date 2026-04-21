# 2026-04-21 First Clean Full Remove

## Context

- Runtime test was executed manually by the user.
- The loaded module was the build from commit:
  - `8e6a23f driver: fix ov5647 remove clientdata lookup`
- Diagnostic profile:
  - `split_v4l2_unregister=1`
  - `unload_marker_delay_ms=500`

Codex did not run `insmod`, `rmmod`, capture, stream, or reboot.

## Result

Manual unload succeeded:

```text
[20260421T150531Z] rmmod rc=0
```

After unload:

- `nv_ov5647` is not listed by `lsmod`;
- `/sys/module/nv_ov5647` is absent;
- no reboot or hang occurred.

## Important Kernel Trace

Primary logs:

- `logs/20260421T150531Z-rmmod-trace.log`
- `logs/20260421T150531Z-rmmod-live-dmesg.log`
- `logs/20260421T150611Z-dmesg-after-clientdata-fix-rmmod-ok.log`

Clean remove path:

```text
nv_ov5647: module exit enter driver_registered=1
nv_ov5647: before i2c_del_driver
nv_ov5647 9-0036: ov5647_remove: enter
nv_ov5647 9-0036: ov5647_remove: state ... s_data->priv=... v4l2_registered=1 ...
nv_ov5647 9-0036: ov5647_split_v4l2subdev_unregister: before v4l2_ctrl_handler_free
nv_ov5647 9-0036: ov5647_split_v4l2subdev_unregister: after v4l2_ctrl_handler_free
nv_ov5647 9-0036: ov5647_split_v4l2subdev_unregister: before v4l2_async_unregister_subdev
tegra-camrtc-capture-vi tegra-capture-vi: subdev nv_ov5647 9-0036 unbind
nv_ov5647 9-0036: ov5647_split_v4l2subdev_unregister: after v4l2_async_unregister_subdev
nv_ov5647 9-0036: ov5647_split_v4l2subdev_unregister: before media_entity_cleanup
nv_ov5647 9-0036: ov5647_split_v4l2subdev_unregister: after media_entity_cleanup
nv_ov5647 9-0036: ov5647_remove: before tegracam_device_unregister
nv_ov5647 9-0036: ov5647_power_put: power rail references cleared
nv_ov5647 9-0036: ov5647_remove: after tegracam_device_unregister
nv_ov5647 9-0036: ov5647_remove: exit success
nv_ov5647: after i2c_del_driver
nv_ov5647: i2c driver unregistered
```

## Interpretation

The previous unload hangs were caused by invalid remove-time state from the incorrect `i2c_get_clientdata()` lookup. The corrected lookup through `to_camera_common_data(&client->dev) -> s_data->priv -> priv->tc_dev` produces valid state and the unload path completes.

This is a green checkpoint for:

- full probe with V4L2 registration;
- manual unload using split unregister diagnostics;
- valid private state at remove;
- clean tegracam device unregister.

## Remaining Work

- Repeat one load/unload cycle with the normal `tegracam_v4l2subdev_unregister()` path after committing this checkpoint.
- If normal unregister is clean, remove or de-emphasize diagnostic split mode for normal workflow.
- Then return to the stream timeout / zero-byte capture problem.
