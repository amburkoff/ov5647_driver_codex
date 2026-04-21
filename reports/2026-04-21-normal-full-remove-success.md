# 2026-04-21 Normal Full Remove Success

## Context

- Runtime test was executed manually by the user.
- Module profile:
  - `full-delay`
  - `split_v4l2_unregister=0`
  - `unload_marker_delay_ms=500`
- This validates the normal framework unregister path after the clientdata lookup fix.

Codex did not run `insmod`, `rmmod`, capture, stream, or reboot.

## Result

Manual unload succeeded:

```text
[20260421T151139Z] rmmod rc=0
```

After unload:

- `nv_ov5647` is not listed by `lsmod`;
- `/sys/module/nv_ov5647` is absent;
- no reboot or hang occurred.

## Important Kernel Trace

Primary logs:

- `logs/20260421T150939Z-manual-insmod-full-delay.log`
- `logs/20260421T151139Z-rmmod-trace.log`
- `logs/20260421T151139Z-rmmod-live-dmesg.log`
- `logs/20260421T151212Z-dmesg-after-normal-rmmod-ok.log`

Clean normal remove path:

```text
nv_ov5647: module exit enter driver_registered=1
nv_ov5647: before i2c_del_driver
nv_ov5647 9-0036: ov5647_remove: enter
nv_ov5647 9-0036: ov5647_remove: state ... v4l2_registered=1 ... split_v4l2_unregister=0
nv_ov5647 9-0036: ov5647_remove: before tegracam_v4l2subdev_unregister
tegra-camrtc-capture-vi tegra-capture-vi: subdev nv_ov5647 9-0036 unbind
nv_ov5647 9-0036: ov5647_remove: after tegracam_v4l2subdev_unregister
nv_ov5647 9-0036: ov5647_remove: before tegracam_device_unregister
nv_ov5647 9-0036: ov5647_power_put: power rail references cleared
nv_ov5647 9-0036: ov5647_remove: after tegracam_device_unregister
nv_ov5647 9-0036: ov5647_remove: exit success
nv_ov5647: after i2c_del_driver
nv_ov5647: i2c driver unregistered
```

## Interpretation

The corrected remove lookup is now validated through the normal NVIDIA r36.5 tegracam unregister path. The previous `rmmod` hangs are considered fixed for the current manual single-sensor full-probe path.

This is a green checkpoint for:

- manual full probe;
- normal V4L2 subdev unregister;
- normal tegracam device unregister;
- module unload without hang.

## Next Step

Return to the streaming issue:

- reload the module manually;
- run one bounded single-frame capture;
- inspect whether the latest `set_mode()` standby fix changes the previous zero-byte timeout behavior.
