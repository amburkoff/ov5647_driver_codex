# 2026-04-17 Boot Profiles Applied

## What Changed

- applied the generated safe/dev boot profiles to `/boot/extlinux/extlinux.conf`;
- set `DEFAULT ov5647-safe`;
- preserved the previous config as a timestamped backup;
- captured additional I2C inventory showing that the base camera bus exists but no downstream camera devices are exposed yet.

## Files Changed

- `/boot/extlinux/extlinux.conf`
- `README.md`
- `docs/09-boot-profiles-and-recovery.md`
- `docs/10-results-and-status.md`

## Commands Run

- apply boot profiles:
  - `sudo ./scripts/switch_boot_profile.sh --apply --default safe`
- inspect boot config:
  - `sed -n '1,220p' /boot/extlinux/extlinux.conf`
- inspect configfs:
  - `find /sys/kernel/config -maxdepth 3 -type d`
- inspect I2C adapters:
  - `i2cdetect -l`
  - `sudo i2cdetect -y 2`

## Logs Saved

- `logs/20260417T120339Z-i2c-bus-inventory.log`
- `logs/20260417T120404Z-boot-profile-apply.log`
- `logs/20260417T120404Z-switch_boot_profile.log`

## Findings

- the on-disk boot menu now contains both mandatory entries:
  - `Jetson SAFE (no OV5647 auto-load)`
  - `Jetson DEV OV5647 auto-load`
- the default boot target on disk is now `ov5647-safe`;
- the current running kernel command line still has no `boot_profile=*` token because this session predates the boot-profile update;
- `configfs` is mounted, but there is no `device-tree/overlays` subtree, so a live DT overlay apply path is not currently proven on this system;
- `i2c-2` exists as the base camera I2C controller, but `sudo i2cdetect -y 2` found no visible downstream camera addresses at this checkpoint.

## Tests Passed

- safe/dev boot entries generated and applied;
- previous `extlinux.conf` backed up;
- no boot-only OV5647 overlay was introduced;
- no auto-load path was introduced.

## Tests Failed

- none in this checkpoint.

## Root-Cause Hypotheses

- the empty `i2c-2` scan is consistent with the absence of an active camera overlay and the absence of a live `cam_i2cmux` path;
- a reboot will be required before `/proc/cmdline` can confirm `boot_profile=ov5647-safe`.

## Next Smallest Step

1. Keep `ov5647-safe` as default.
2. Continue preparing the first one-port OV5647 DT enablement path.
3. Reboot only when a specific overlay/autoload hypothesis is ready to validate.

## Reboot Needed

- Not yet.

## Default Boot Profile On Disk

- `ov5647-safe`
