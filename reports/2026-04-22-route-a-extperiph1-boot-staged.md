# 2026-04-22 Route A Extperiph1 Boot Staged

## Summary

Route A has been staged as the next dev-profile overlay with the corrected Tegra234 `TEGRA234_CLK_EXTPERIPH1` clock ID. This is a controlled DT-only retest because earlier route-A captures were performed before the clock-ID bug was found.

## Changes

- Built `patches/ov5647-p3768-port-a-probe.dts`.
- Installed `/boot/ov5647-p3768-port-a-extperiph1.dtbo`.
- Switched dev boot entry to:
  - `OVERLAYS /boot/ov5647-p3768-port-a-extperiph1.dtbo`
- Kept safe boot entry:
  - `Jetson SAFE (no OV5647 auto-load)`
- Kept default boot profile:
  - `DEFAULT ov5647-dev`

## Verified Before Reboot

- `/boot/extlinux/extlinux.conf` contains both safe and dev labels.
- Dev label has `boot_profile=ov5647-dev`.
- Safe label has `boot_profile=ov5647-safe`.
- DTBO decompile shows:
  - `i2c@0`;
  - `ov5647_a@36`;
  - `clocks = <... 0x24>`;
  - `tegra_sinterface = "serial_b"`;
  - `port-index = <1>`;
  - `lane_polarity = "6"`.

## Next Step

Reboot is required for the DT overlay to apply. Codex must not run the reboot command. After the user runs `sudo reboot`, collect post-reboot state and verify live DT before any `insmod` or capture test.

Expected post-reboot checks:

- `/proc/cmdline` contains `boot_profile=ov5647-dev`;
- live DT contains route-A node `cam_i2cmux/i2c@0/ov5647_a@36`;
- route-A live DT clock cell is `0x24`;
- no automatic `nv_ov5647` load happened before manual testing.

## Logs

- `logs/20260422T140100Z-build-route-a-extperiph1-overlay-wrapper.log`
- `logs/20260422T140200Z-stage-route-a-extperiph1-overlay-checksum-full.log`
- `logs/20260422T140230Z-switch-dev-to-route-a-extperiph1.log`
- `logs/20260422T140300Z-verify-extlinux-route-a-extperiph1.log`
- `logs/20260422T140300Z-verify-route-a-boot-profile-fields.log`
- `logs/20260422T140300Z-verify-route-a-dtbo-fields.log`
