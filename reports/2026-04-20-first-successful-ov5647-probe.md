# 2026-04-20 First Successful OV5647 Probe

## What Changed

- confirmed the updated dev overlay is active in the live device tree;
- verified the OV5647 responds on the muxed downstream camera bus;
- identified the current working `pwdn` polarity for this path empirically;
- fixed probe-time control registration by removing `TEGRA_CAMERA_CID_GROUP_HOLD` from the driver control list;
- reached the first successful sensor probe and first `/dev/video0`.

## Files Changed

- `src/nv_ov5647/nv_ov5647.c`
- `docs/01a-cbl-carrier-mapping.md`
- `docs/10-results-and-status.md`
- `docs/11-known-issues.md`

## Commands Run

- post-reboot confirmation:
  - `cat /proc/cmdline`
  - `sudo ./scripts/collect_post_reboot.sh`
  - `sudo dtc -I fs -O dts /proc/device-tree | sed -n '/ov5647_a@36 {/,/};/p'`
- direct bus confirmation:
  - `sudo i2cdetect -y 9`
  - `sudo i2ctransfer -f -y 9 w2@0x36 0x30 0x0a r1`
  - `sudo i2ctransfer -f -y 9 w2@0x36 0x30 0x0b r1`
- module iterations:
  - `./scripts/build_module.sh`
  - `sudo rmmod nv_ov5647`
  - `sudo insmod ./src/nv_ov5647/nv_ov5647.ko register_i2c_driver=1 allow_hw_probe=1`
- node checks:
  - `ls -l /dev/video* /dev/v4l-subdev* /dev/media*`
  - `find /sys/class/video4linux`

## Logs Saved

- `logs/20260420T083349Z-collect_post_reboot.log`
- `logs/20260420T0834Z-probe-after-mclk-overlay.log`
- `logs/20260420T0840Z-build-module-after-priv-cleanup.log`
- `logs/20260420T0840Z-probe-after-priv-cleanup.log`
- `logs/20260420T0842Z-rmmod-after-failed-probe.log`
- `logs/20260420T0842Z-i2cdetect-bus9-after-mclk-fix.log`
- `logs/20260420T0844Z-i2ctransfer-chipid-high.log`
- `logs/20260420T0844Z-i2ctransfer-chipid-low.log`
- `logs/20260420T0849Z-build-module-direct-i2c-serial.log`
- `logs/20260420T0849Z-probe-direct-i2c-serial.log`
- `logs/20260420T0853Z-build-module-pwdn-high.log`
- `logs/20260420T0853Z-probe-pwdn-high.log`
- `logs/20260420T0855Z-build-module-no-group-hold.log`
- `logs/20260420T0855Z-probe-no-group-hold.log`

## Artifacts Saved

- `artifacts/post-reboot/20260420T083349Z/`
- `artifacts/build/20260420T083646Z/`
- `artifacts/build/20260420T083918Z/`
- `artifacts/build/20260420T084004Z/`
- `artifacts/build/20260420T084024Z/`

## Findings

- the active live OV5647 node now contains:
  - `mclk = "extperiph1"`
  - `clocks = <&bpmp 0x07>`
  - `tegra_sinterface = "serial_b"`
  - `num_lanes = "2"`
  - `lane_polarity = "6"`
- the current active bus path is:
  - base camera controller `i2c-2`
  - muxed downstream bus `i2c-9`
  - sensor address `0x36`
- direct bus reads confirmed:
  - chip ID high `0x56`
  - chip ID low `0x47`
  - combined chip ID `0x5647`
- the original power-on assumption for `pwdn_gpio=397` was wrong for the current live path;
- chip-ID reads failed when power-on drove GPIO 397 low;
- chip-ID reads succeeded when power-on kept GPIO 397 high;
- after that polarity change, `ov5647_board_setup()` succeeded;
- after removing `TEGRA_CAMERA_CID_GROUP_HOLD` from the control list, `tegracam_v4l2subdev_register()` succeeded;
- the kernel now reports:
  - `tegra-camrtc-capture-vi tegra-capture-vi: subdev nv_ov5647 9-0036 bound`
  - `ov5647_probe: exit success`
- the system now has:
  - `/dev/video0`
  - `/dev/v4l-subdev0`
  - `/dev/v4l-subdev1`
  - `/dev/media0`

## Tests Passed

- dev reboot applied the updated overlay successfully;
- controlled module load no longer panics the kernel;
- `mclk` acquisition succeeds;
- direct chip-ID reads from bus `9` succeed;
- driver chip-ID probe succeeds;
- control registration succeeds after the `GROUP_HOLD` list fix;
- first successful probe completed;
- first `/dev/video0` appeared.

## Tests Failed

- failure-unwind path still triggers a `devm_kfree` warning when probe exits through `tegracam_device_unregister()` on negative test paths;
- raw capture has not been attempted yet;
- preview has not been attempted yet.

## Root-Cause Hypotheses

- confirmed:
  - the main hardware-facing bring-up blocker after the DT fix was the assumed `pwdn` polarity;
- current open hypothesis:
  - the remaining failure-path warning is a tegracam-framework cleanup interaction specific to early probe failures, not to the successful path that now binds the sensor.

## Next Smallest Step

1. Install `v4l-utils` tooling if allowed on the target.
2. Capture `media-ctl -p`, `v4l2-ctl --all`, `--list-formats-ext`, and `v4l2-compliance`.
3. Validate the minimal mode table against the DT mode.
4. Attempt the first raw frame capture from `/dev/video0`.

## Reboot Needed

- No.

## Default Boot Profile On Disk

- `ov5647-dev`
