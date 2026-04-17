# Boot Profiles And Recovery

## Current State

The running system currently has:

- one active boot label: `primary`;
- `DEFAULT primary`;
- no `boot_profile=ov5647-safe`;
- no `boot_profile=ov5647-dev`.

This does not yet satisfy the repository safety policy.

## Prepared Workflow

The repository now includes `scripts/switch_boot_profile.sh`, which:

- reads the current `extlinux.conf`;
- derives a safe candidate pair of boot entries;
- writes a generated config under `artifacts/boot/<timestamp>/`;
- optionally applies it only when explicitly asked and run as root.

Generated entries:

- `ov5647-safe`
  - menu label: `Jetson SAFE (no OV5647 auto-load)`
  - adds `boot_profile=ov5647-safe`
- `ov5647-dev`
  - menu label: `Jetson DEV OV5647 auto-load`
  - adds `boot_profile=ov5647-dev`

Current design choice:

- both generated entries stay functionally identical to the current primary boot path until OV5647 overlay validation is ready;
- this preserves recoverability while adding an unambiguous post-boot identity token.

## Recovery Policy

- safe profile must remain available at all times;
- safe profile should stay the default until manual OV5647 probe and remove are stable;
- recovery action is to set `DEFAULT ov5647-safe` and reboot.

