# Boot Profiles And Recovery

## Current State

The running kernel session currently has:

- no `boot_profile=ov5647-safe` in `/proc/cmdline`;
- no `boot_profile=ov5647-dev` in `/proc/cmdline`.

This is expected until the first reboot after the boot-profile change.

The on-disk boot configuration now has:

- `DEFAULT ov5647-safe`;
- `LABEL ov5647-safe`;
- `LABEL ov5647-dev`;
- backup saved as `/boot/extlinux/extlinux.conf.20260417T120404Z.bak`.

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

## Recovery Policy

- safe profile must remain available at all times;
- safe profile should stay the default until manual OV5647 probe and remove are stable;
- recovery action is to set `DEFAULT ov5647-safe` and reboot.
