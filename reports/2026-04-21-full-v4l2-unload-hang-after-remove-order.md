# 2026-04-21 Full V4L2 Unload Hang After Remove-Order Patch

## What Happened

- the user manually loaded the module with full V4L2 registration:
  - `register_i2c_driver=1 allow_hw_probe=1`
- the user manually ran:
  - `sudo /home/cam/ov5647_driver_codex/scripts/run_manual_rmmod_trace.sh`
- the Jetson hung during unload;
- the user manually rebooted the system.

## Collected Artifacts

- unload attempt:
  - `logs/20260421T085648Z-rmmod-trace.log`
  - `logs/20260421T085648Z-rmmod-live-dmesg.log`
  - `logs/20260421T085648Z-rmmod-pre-dmesg-tail.log`
- post-reboot:
  - `artifacts/post-reboot/20260421T090055Z/`
  - `logs/20260421T091800Z-collect_post_reboot-after-full-unload-hang.log`

## Findings

- the post-reboot profile is still:
  - `boot_profile=ov5647-dev`
- `pstore` is empty again:
  - no `console-ramoops`
  - no `dmesg-ramoops`
- the module is not loaded after reboot;
- `last -x` records the previous session as a crash;
- the live `dmesg -W` trace for the failing full unload is empty;
- the pre-rmmod dmesg tail confirms full probe succeeded:
  - `skip_v4l2_register=0`
  - `subdev nv_ov5647 9-0036 bound`
  - `ov5647_probe: exit success`
  - `i2c driver registered`

## Interpretation

- removing the direct `ov5647_power_off()` call from `remove()` did not fix the full V4L2 unload hang;
- the previous isolated test still matters:
  - `skip_v4l2_register=1` unload succeeds;
  - full V4L2 registration unload hangs;
- the failure remains tied to V4L2 subdev/media graph registration or references created by that path.

## Corrective Action Applied

- updated `run_manual_rmmod_trace.sh` to:
  - write `dmesg -W` output line-by-line;
  - call `sync` after each received kernel line;
  - save media/video/subdev node list;
  - save `fuser -v` output for those nodes;
  - save `lsof` output for those nodes.

## Next Best Step

Do not run another full unload test until a new checkpoint is committed and pushed.

The next manual full unload test should first answer whether any process holds:

- `/dev/video*`
- `/dev/media*`
- `/dev/v4l-subdev*`

If no process holds these nodes, add a narrower driver-side isolation switch for the V4L2 unregister phase.
