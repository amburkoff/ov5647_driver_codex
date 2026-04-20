# 2026-04-20 Third Reboot RMMOD Hang

## What Happened

- the user manually ran:
  - `sudo rmmod nv_ov5647`
- the Jetson hung instead of returning from `rmmod`;
- the user then manually power-cycled / rebooted the board.

## What Is Confirmed

- `last -x` records the prior session as:
  - `crash`
- the current boot is again:
  - `boot_profile=ov5647-dev`
- unlike the previous reboot, the current boot does not expose usable `pstore` records for the hang, so the exact blocked frame is not yet preserved.

## Interpretation

- the earlier NULL-dereference panic in `ov5647_remove -> ov5647_power_off` was not the only unload bug;
- with the current guarded code, `rmmod` still reaches a hang condition somewhere in the unload path;
- because the user manually ran the unload after the new checkpoint, this result now cleanly belongs to the currently built module image.

## Corrective Action Applied

- added step logging around the remaining unload phases:
  - before/after `tegracam_v4l2subdev_unregister()`
  - before/after `tegracam_device_unregister()`
- future risky tests must remain manual-only, one command at a time.

## Next Smallest Step

1. Rebuild and commit the new remove-path instrumentation.
2. Ask the user to manually load the freshly built module.
3. Ask the user to manually unload it again.
4. After reboot, inspect the last successful remove-stage log to identify the exact hang boundary.

## Reboot Needed

- No additional reboot is required right now.

## Default Boot Profile On Disk

- `ov5647-dev`
