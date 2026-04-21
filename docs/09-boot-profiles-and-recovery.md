# Boot Profiles And Recovery

## Current State

The on-disk boot configuration is staged for the route-C overlay experiment:

- `DEFAULT ov5647-dev`;
- `LABEL ov5647-safe`;
- `LABEL ov5647-dev`;
- safe profile has no OV5647 overlay;
- dev profile uses `OVERLAYS /boot/ov5647-p3768-port-c-probe.dtbo`;
- latest backup saved as `/boot/extlinux/extlinux.conf.20260421T155602Z.bak`.

After the next reboot, the first required check is:

```bash
cat /proc/cmdline
```

Expected marker:

```text
boot_profile=ov5647-dev
```

## Prepared Workflow

The repository now includes `scripts/switch_boot_profile.sh`, which:

- reads the current `extlinux.conf`;
- derives a safe candidate pair of boot entries;
- writes a generated config under `artifacts/boot/<timestamp>/`;
- can inject one explicit dev-only overlay path with `--dev-overlay /boot/<name>.dtbo`;
- optionally applies it only when explicitly asked and run as root.

Generated entries:

- `ov5647-safe`
  - menu label: `Jetson SAFE (no OV5647 auto-load)`
  - adds `boot_profile=ov5647-safe`
- `ov5647-dev`
  - menu label: `Jetson DEV OV5647 auto-load`
  - adds `boot_profile=ov5647-dev`

Current design choice:

- both entries stay functionally identical to the previous `primary` boot path until OV5647 overlay validation is ready;
- this preserves recoverability while adding an unambiguous post-boot identity token.
- when requested, only the dev entry may carry an explicit `FDTOVERLAYS` path; the safe entry must stay overlay-free.
- on this r36.x target, local NVIDIA `jetson-io` tooling indicates the UEFI/L4tLauncher path should use `FDT + OVERLAYS`, not `FDTOVERLAYS`.
- current corrected dev entry points at:
  - `FDT /boot/dtb/kernel_tegra234-p3768-0000+p3767-0000-nv.dtb`
  - `OVERLAYS /boot/ov5647-p3768-port-c-probe.dtbo`

## Recovery Policy

- safe profile must remain available at all times;
- safe profile must remain manually selectable even when dev is temporarily set as `DEFAULT` for a controlled reboot experiment;
- recovery action is to set `DEFAULT ov5647-safe` and reboot.
