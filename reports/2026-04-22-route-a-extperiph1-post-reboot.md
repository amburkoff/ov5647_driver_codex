# 2026-04-22 Route A Extperiph1 Post-Reboot

## Summary

The Jetson rebooted successfully into the dev profile with the route-A corrected-MCLK overlay. No `nv_ov5647` auto-load occurred. The live DT now confirms route A, so the next risky step is manual `insmod` diagnostics only.

## Verified

- `/proc/cmdline` contains `boot_profile=ov5647-dev`.
- `/boot/extlinux/extlinux.conf` keeps both profiles:
  - `Jetson SAFE (no OV5647 auto-load)`;
  - `Jetson DEV OV5647 auto-load`.
- Dev profile uses:
  - `/boot/ov5647-p3768-port-a-extperiph1.dtbo`.
- `nv_ov5647` is not loaded.
- `/dev/video0` is absent before module load.
- Live DT route:
  - `cam_i2cmux/i2c@0`;
  - `ov5647_a@36`;
  - `clocks_hex = 00 00 00 03 00 00 00 24`;
  - `tegra_sinterface = serial_b`;
  - `lane_polarity = 6`;
  - endpoint `port-index = 1`;
  - endpoint `bus-width = 2`.
- Route C node is absent.

## Pstore

`/sys/fs/pstore/console-ramoops-0` exists after reboot. It contains the previous boot's console history, including the earlier route-C capture timeout and `reboot: Restarting system`.

No explicit kernel panic, oops, NULL dereference, or `Unable to handle kernel` signature was found in the pstore grep. Treat it as residual evidence from the previous controlled reboot unless later symptoms contradict this.

## Next Step

Ask the user to manually run route-A insmod diagnostics:

```bash
sudo /home/cam/ov5647_driver_codex/scripts/run_manual_insmod_diag.sh full-delay-dump-contclk-mclk24
```

Do not run capture until the route-A probe, chip ID, `/dev/video0`, media graph, and active 24 MHz MCLK are confirmed.

## Logs

- `logs/20260422T140504Z-post-route-a-reboot-basic-state.log`
- `logs/20260422T140504Z-post-route-a-reboot-live-dt.log`
- `logs/20260422T140521Z-post-route-a-reboot-readonly-media-i2c-clock.log`
- `logs/20260422T140535Z-post-route-a-reboot-console-ramoops-inspect.log`
- `logs/20260422T140550Z-route-state-summary-after-route-a-reboot.log`
