# 2026-04-17 Dev Overlay Boot Render

## What Changed

- extended `scripts/switch_boot_profile.sh` with `--dev-overlay /boot/<name>.dtbo`;
- normalized inherited `APPEND` lines so existing `boot_profile=*` tokens are stripped before new ones are appended;
- rendered a candidate boot config where:
  - safe profile stays overlay-free;
  - dev profile adds exactly one `FDTOVERLAYS /boot/ov5647-p3768-port-a-probe.dtbo`.

## Files Changed

- `scripts/switch_boot_profile.sh`

## Commands Run

- `./scripts/switch_boot_profile.sh --render-only --default safe --dev-overlay /boot/ov5647-p3768-port-a-probe.dtbo`
- `sed -n '1,220p' artifacts/boot/20260417T124821Z/extlinux.conf.generated`

## Logs Saved

- `logs/20260417T124821Z-switch_boot_profile.log`

## Artifacts Saved

- `artifacts/boot/20260417T124821Z/extlinux.conf.current`
- `artifacts/boot/20260417T124821Z/extlinux.conf.generated`

## Tests Passed

- dev-only overlay injection works in render-only mode;
- safe entry remains free of `FDTOVERLAYS`;
- dev entry carries only one `boot_profile=ov5647-dev`;
- inherited `boot_profile=ov5647-safe` is no longer duplicated into the dev stanza.

## Tests Failed

- the first render attempt exposed a boot-profile token duplication bug in the script.

## Root-Cause Hypothesis For The Failed Attempt

- the script was reusing an `APPEND` line from an already profile-tagged source stanza;
- without normalization, inherited `boot_profile=ov5647-safe` leaked into the generated dev stanza.

## Findings

- the repository now has a reproducible path to prepare a dev boot entry with one explicit overlay file while keeping the safe entry unchanged;
- this is sufficient to prepare a future reboot experiment without yet modifying the live on-disk boot config for that overlay.

## Next Smallest Step

1. Copy the selected probe `.dtbo` into `/boot/` only when the first reboot experiment is ready.
2. Re-render and then apply the dev boot entry with that exact overlay path.
3. Reboot only after the overlay file, module path, and test commands are all fixed and logged.

## Reboot Needed

- No.
