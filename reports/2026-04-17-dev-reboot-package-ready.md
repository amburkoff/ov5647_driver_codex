# 2026-04-17 Dev Reboot Package Ready

## What Changed

- staged the selected one-port probe overlay into `/boot/ov5647-p3768-port-a-probe.dtbo`;
- verified the staged file checksum against the repository artifact;
- applied a new `extlinux.conf` where:
  - `DEFAULT ov5647-dev`
  - `ov5647-safe` remains overlay-free
  - `ov5647-dev` adds `FDTOVERLAYS /boot/ov5647-p3768-port-a-probe.dtbo`

## Files Changed

- `/boot/ov5647-p3768-port-a-probe.dtbo`
- `/boot/extlinux/extlinux.conf`

## Commands Run

- `sha256sum artifacts/dtbo/20260417T124633Z-ov5647-p3768-port-a-probe.dtbo`
- `sudo cp artifacts/dtbo/20260417T124633Z-ov5647-p3768-port-a-probe.dtbo /boot/ov5647-p3768-port-a-probe.dtbo`
- `sha256sum /boot/ov5647-p3768-port-a-probe.dtbo`
- `sudo ./scripts/switch_boot_profile.sh --apply --default dev --dev-overlay /boot/ov5647-p3768-port-a-probe.dtbo`
- `sed -n '1,220p' /boot/extlinux/extlinux.conf`

## Logs Saved

- `logs/20260417T131127Z-stage-probe-dtbo.log`
- `logs/20260417T131127Z-switch_boot_profile.log`
- `logs/20260417T131127Z-prepare-dev-boot-with-overlay.log`

## Artifacts Saved

- `artifacts/boot/20260417T131127Z/extlinux.conf.current`
- `artifacts/boot/20260417T131127Z/extlinux.conf.generated`

## Findings

- repository probe overlay checksum:
  - `d04e7c4dffc379787150e0be617594426f4a508ce50cd460444b8b768e6d4f08`
- staged `/boot` overlay checksum matches exactly;
- the on-disk boot default is now `ov5647-dev`;
- the safe recovery entry is still present and does not carry any OV5647 overlay.

## Tests Passed

- exact probe overlay copied into `/boot`;
- dev boot entry rendered and applied with one explicit overlay path;
- safe entry preserved;
- previous extlinux configuration backed up as `/boot/extlinux/extlinux.conf.20260417T131127Z.bak`.

## Tests Failed

- none in this checkpoint.

## Next Smallest Step

1. Reboot into the prepared dev profile.
2. Confirm `boot_profile=ov5647-dev` from `/proc/cmdline`.
3. Collect post-reboot logs and live DT state.
4. Attempt the first controlled OV5647 probe and chip-id read.

## Reboot Needed

- Yes.

## Default Boot Profile On Disk

- `ov5647-dev`
