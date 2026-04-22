# 2026-04-22 Route-C Insmod Success

## Summary

Manual route-C `insmod` succeeded after the route-C overlay reboot. The driver probed the OV5647 on the route-C path, read chip ID `0x5647`, registered V4L2/media entities, and created `/dev/video0`.

No capture or streaming test was run by Codex.

## User-Run Command

```bash
sudo /home/cam/ov5647_driver_codex/scripts/run_manual_insmod_diag.sh full-delay
```

Result:

```text
insmod rc=0
```

## Module Identity

- loaded module: `nv_ov5647`
- loaded `srcversion`: `2F4050CDED69B8A5FF0C49F`
- built `srcversion`: `2F4050CDED69B8A5FF0C49F`
- parameters:
  - `register_i2c_driver=Y`
  - `allow_hw_probe=Y`
  - `skip_v4l2_register=N`
  - `skip_v4l2_unregister=N`
  - `split_v4l2_unregister=N`
  - `unload_marker_delay_ms=500`

## Probe Result

Kernel log:

- `ov5647_probe: enter client=ov5647 addr=0x36`;
- `ov5647_parse_dt`: `mclk=extperiph1`, `reset_gpio=-1`, `pwdn_gpio=486`, supplies `vana/vdig/vif`;
- dummy regulators were used for `vana`, `vdig`, and `vif`;
- `ov5647_power_on` completed and logged `stream-stop LP-11 setup complete`;
- chip ID detected: `0x5647`;
- VI bound the subdev;
- `ov5647_probe: exit success`.

## V4L2 / Media Result

Created nodes:

- `/dev/video0`;
- `/dev/media0`;
- `/dev/v4l-subdev0`;
- `/dev/v4l-subdev1`.

Video node:

- card: `vi-output, nv_ov5647 9-0036`;
- bus info: `platform:tegra-capture-vi:2`;
- format: `BG10 640x480`;
- frame interval: `30 fps`.

Media graph:

- `nv_ov5647 9-0036 -> nvcsi -> vi-output`;
- all links enabled.

## Route-C Facts Confirmed By Probe

- route-C uses Linux `i2c-9` after this boot;
- sensor address remains `0x36`;
- chip ID is `0x5647`;
- route-C PWDN GPIO resolves to Linux GPIO `486`;
- `/dev/video0` appears on VI capture route `2`.

## Logs

- `logs/20260422T080020Z-manual-insmod-full-delay.log`
- `logs/20260422T080020Z-manual-insmod-full-delay.dmesg-tail.log`
- `logs/20260422T080020Z-manual-insmod-full-delay.modinfo.log`
- `logs/20260422T080049Z-after-route-c-manual-insmod-state.log`
- `logs/20260422T080049Z-after-route-c-manual-insmod-v4l2.log`
- `logs/20260422T080049Z-after-route-c-manual-insmod-media-ctl.log`
- `logs/20260422T080049Z-after-route-c-manual-insmod-dmesg-tail.log`
- `logs/20260422T080049Z-after-route-c-manual-insmod-script-log-summary.log`

## Next Step

The next risky step is a manual single-frame capture on route C:

```bash
sudo /home/cam/ov5647_driver_codex/scripts/run_manual_single_frame_trace.sh
```

Codex should not run it because `STREAMON` can still hang or reboot the Jetson.
