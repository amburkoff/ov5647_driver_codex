# 2026-04-21 RMMOD Hang Before Visible Module Exit

## What Happened

- the user manually ran:
  - `sudo /home/cam/ov5647_driver_codex/scripts/run_manual_rmmod_trace.sh`
- the helper printed:
  - `[20260421T084418Z] starting live dmesg capture`
  - `[20260421T084418Z] collecting pre-rmmod state`
  - `[20260421T084418Z] running: rmmod nv_ov5647`
- the Jetson hung during unload;
- the user manually rebooted the board.

## Collected Artifacts

- unload attempt:
  - `logs/20260421T084418Z-rmmod-trace.log`
  - `logs/20260421T084418Z-rmmod-live-dmesg.log`
  - `logs/20260421T084418Z-rmmod-pre-dmesg-tail.log`
- post-reboot:
  - `artifacts/post-reboot/20260421T084801Z/`
  - `logs/20260421T084801Z-collect_post_reboot.log`
  - `logs/20260421T085100Z-collect_post_reboot-sudo.log`

## Findings

- active profile after reboot:
  - `boot_profile=ov5647-dev`
- `pstore` is empty after this hang:
  - no `console-ramoops`
  - no `dmesg-ramoops`
- the preserved unload log contains successful probe and `i2c driver registered`;
- the preserved unload log does not contain:
  - `module exit enter`
  - `before i2c_del_driver`
  - `ov5647_remove: enter`
  - any later tegracam unregister marker.

## Interpretation

- the loaded `.ko` did contain the new `module exit enter` string, so this was not an old binary;
- the hang occurs before the first visible printk from `module_exit()`, or the system locks hard enough that this printk never reaches the persistent log;
- repeating the same full V4L2-registration unload test is not useful until the path is isolated further.

## Corrective Action Applied

- added module parameter:
  - `skip_v4l2_register`
- when `skip_v4l2_register=1`, probe still performs DT parse, tegracam device register, power setup, and chip-ID detection, but returns before `tegracam_v4l2subdev_register()`;
- remove now tracks whether V4L2 subdev registration happened and skips `tegracam_v4l2subdev_unregister()` when it did not;
- `run_manual_rmmod_trace.sh` now uses `dmesg -W` so the live trace file contains only new messages after helper startup.

## Next Smallest Test

1. Manually load the new module with:
   - `skip_v4l2_register=1`
2. If load succeeds, manually run the same unload helper once.
3. If unload succeeds in this isolated mode, the full unload hang is likely tied to V4L2 subdev/media graph registration or references created by it.
4. If unload still hangs, the issue is earlier than V4L2 registration and likely in I2C driver removal, tegracam device registration, or module removal state.

## Safety Policy

- Do not run unload or streaming from Codex.
- Every unload/capture/STREAMON test remains manual-only, one command at a time.
