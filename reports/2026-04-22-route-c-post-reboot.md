# 2026-04-22 Route-C Post Reboot

## Summary

The Jetson booted successfully after the route-C boot staging. The active boot profile is `ov5647-dev`, the route-C overlay is present in live DT, and no pstore/ramoops crash record was present.

No module load, unload, or capture was run by Codex after this reboot.

## Confirmed Boot State

- `/proc/cmdline` contains `boot_profile=ov5647-dev`.
- `/boot/extlinux/extlinux.conf` still has `DEFAULT ov5647-dev`.
- dev entry uses `OVERLAYS /boot/ov5647-p3768-port-c-probe.dtbo`.
- safe entry remains present and has no `OVERLAYS`.
- route-C DTBO SHA256 in `/boot`:
  - `85eed7f0b43e4ac7226759075b881e636efd898351c54fdf96f5913a768921d0`

## Live DT Result

Route-C overlay is applied:

- sensor node: `/bus@0/cam_i2cmux/i2c@1/ov5647_c@36`;
- badge: `probe_ov5647_route_c`;
- `tegra_sinterface = "serial_c"`;
- `lane_polarity = "0"`;
- endpoint `bus-width = <2>`;
- endpoint `port-index = <2>`;
- `pwdn-gpios = <... 0xa0 0>`.

I2C mux mapping after route-C boot:

- `i2c-9`: `i2c-2-mux (chan_id 1)`, route-C;
- `i2c-10`: `i2c-2-mux (chan_id 0)`, route-A.

## Runtime State

- `nv_ov5647` is not loaded.
- `/dev/video0` is absent.
- `/dev/media0` exists.
- media graph currently contains only the base NVCsi entity with no sensor link.

This is expected because experimental module autoload is still not enabled.

## Crash Evidence

- `/sys/fs/pstore` is empty.
- No route-C boot panic/oops evidence was captured.

## Logs And Artifacts

- `logs/20260422T075607Z-post-route-c-reboot-cmdline-basic.log`
- `logs/20260422T075607Z-post-route-c-reboot-boot-state.log`
- `logs/20260422T075607Z-post-route-c-reboot-pstore.log`
- `logs/20260422T075607Z-post-route-c-reboot-media-state.log`
- `logs/20260422T075627Z-post-route-c-live-dt-camera-grep.log`
- `logs/20260422T075627Z-post-route-c-i2c-inventory.log`
- `logs/20260422T075627Z-post-route-c-dmesg-camera-errors.log`
- `logs/20260422T075627Z-post-route-c-journal-k-camera-errors.log`
- `artifacts/dt/20260422T075627Z-post-route-c-reboot/live-device-tree.dts`
- `artifacts/post-reboot/20260422T075643Z/`

## Next Step

The next risky step is manual module load on route C:

```bash
sudo /home/cam/ov5647_driver_codex/scripts/run_manual_insmod_diag.sh full-delay
```

Codex should not run this command because an `insmod` can still hang or reboot the Jetson.
