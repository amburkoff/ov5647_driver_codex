# 2026-04-20 Second Reboot RMMOD Crash

## What Happened

- the Jetson rebooted again during the unload-retest phase;
- this was not a network disconnect;
- `pstore/ramoops` confirms a kernel Oops followed by panic during module removal.

## Trigger Context

- a previous parallel tool run let `insmod` execute before the rebuilt `.ko` had finished building;
- that means the kernel was still running the older already-loaded module image when the later unload retest was attempted;
- the remove-guard code was present in the working tree but was not yet the image actually loaded into the kernel for that retest.

## Reboot Cause

From `pstore`:

- `nv_ov5647 9-0036: ov5647_remove: enter`
- `Unable to handle kernel NULL pointer dereference`
- call trace includes:
  - `ov5647_power_off`
  - `ov5647_remove`
  - `nv_ov5647_exit`
- the log ends with:
  - `Kernel panic - not syncing: Oops: Fatal exception`

## Files Changed

- `src/nv_ov5647/nv_ov5647.c`
- `docs/11-known-issues.md`

## Commands Run

- post-reboot collection:
  - `cat /proc/cmdline`
  - `sudo ./scripts/collect_post_reboot.sh`
- crash forensics:
  - `sudo grep -nE 'Unable to handle|Internal error|Kernel panic|ov5647_remove|ov5647_power_off|nv_ov5647_exit|Call trace|panic' /sys/fs/pstore/...`
  - `last -x | head -n 20`
- safe rebuild after reboot:
  - `./scripts/build_module.sh`

## Logs Saved

- `logs/20260420T085452Z-collect_post_reboot.log`
- `logs/20260420T085557Z-build_module.log`
- `logs/20260420T0859Z-build-module-remove-guard.log`
- `logs/20260420T0859Z-insmod-after-remove-guard.log`
- `logs/20260420T0900Z-dmesg-before-rmmod-retest.log`
- `logs/20260420T0900Z-modinfo-current-ko.log`
- `logs/20260420T0908Z-build-module-remove-guard-serial.log`

## Artifacts Saved

- `artifacts/post-reboot/20260420T085452Z/`
- `artifacts/post-reboot/20260420T090627Z/`
- `artifacts/build/20260420T085557Z/`
- `artifacts/build/20260420T090649Z/`

## Findings

- the second spontaneous reboot was caused by `rmmod`, not by `v4l2-ctl --all`;
- the crash path is inside driver removal, specifically through `ov5647_power_off()` from `ov5647_remove()`;
- the current repository state now includes a guard change in `power_off/remove`, but that guarded image was not the one that crashed;
- after this event, risky runtime tests must be driven manually by the user, one command at a time, only after a checkpoint is committed.

## Next Smallest Step

1. Commit the current remove-guard checkpoint and the crash report.
2. Ask the user to run exactly one manual command to load the freshly built module.
3. If that succeeds, ask for exactly one manual `rmmod` retest.
4. Only after unload is proven safe, return to streaming work.

## Reboot Needed

- No additional reboot is currently required.

## Default Boot Profile On Disk

- `ov5647-dev`
