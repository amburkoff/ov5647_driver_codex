# 2026-04-22 Route-C Continuous Clock Boot Staged

## Summary

The route-C continuous-clock DT overlay was staged into the dev boot profile for the next controlled reboot.

No reboot was performed by Codex.

## Applied Boot State

Current `/boot/extlinux/extlinux.conf` now has:

- `DEFAULT ov5647-dev`;
- safe profile retained:
  - `LABEL ov5647-safe`;
  - `boot_profile=ov5647-safe`;
  - no OV5647 overlay;
- dev profile:
  - `LABEL ov5647-dev`;
  - `boot_profile=ov5647-dev`;
  - `OVERLAYS /boot/ov5647-p3768-port-c-contclk.dtbo`.

The previous boot config was backed up by the script as:

- `/boot/extlinux/extlinux.conf.20260422T083143Z.bak`

## Overlay

Staged DTBO:

- `/boot/ov5647-p3768-port-c-contclk.dtbo`

This DTBO has:

- route C;
- `tegra_sinterface = "serial_c"`;
- `port-index = <2>`;
- `bus-width = <2>`;
- `lane_polarity = "0"`;
- `discontinuous_clk = "no"`.

## Reason Reboot Is Required

`discontinuous_clk` is parsed from the live device tree at boot. The current running system still uses the previous live DT until reboot.

## Logs

- `logs/20260422T083345Z-apply-boot-route-c-contclk.log`
- `logs/20260422T083345Z-extlinux-after-route-c-contclk-apply.log`

## Post-Reboot Plan

After reboot:

1. confirm `/proc/cmdline` includes `boot_profile=ov5647-dev`;
2. confirm live DT has `discontinuous_clk = "no"`;
3. confirm pstore/ramoops is empty or capture it if present;
4. manually load the module with:

```bash
sudo /home/cam/ov5647_driver_codex/scripts/run_manual_insmod_diag.sh full-delay-dump-contclk
```

5. manually run one capture:

```bash
sudo /home/cam/ov5647_driver_codex/scripts/run_manual_single_frame_trace.sh
```
