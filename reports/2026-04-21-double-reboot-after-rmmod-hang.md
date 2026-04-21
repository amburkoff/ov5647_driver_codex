# 2026-04-21 Double Reboot After rmmod Hang

## Context

- user reported a hang during manual `rmmod`;
- user then manually rebooted;
- user then accidentally ran another `sudo reboot`;
- no risky module, stream, capture, or reboot command was run by Codex during this analysis.

## Current Boot

- active profile:
  - `boot_profile=ov5647-dev`
- boot time from `who -b`:
  - `2026-04-21 13:14 MSK`
- `nv_ov5647` is not currently loaded;
- `/dev/media0` exists;
- `/dev/video*` and `/dev/v4l-subdev*` are absent.

Logs:

- `logs/20260421T101619Z-post-double-reboot-basic-state.log`
- `logs/20260421T101619Z-post-double-reboot-module-devnodes-pstore.log`

## pstore / ramoops

- `/sys/fs/pstore/console-ramoops-0` exists and was saved under:
  - `artifacts/post-reboot/20260421T101649Z-double-reboot/pstore/console-ramoops-0`
- pstore content ends with:
  - `reboot: Restarting system`
- no `nv_ov5647`, oops, panic, or stack trace appears in the preserved ramoops content.

Interpretation:

- this ramoops most likely corresponds to the later accidental clean `sudo reboot`;
- it does not preserve useful evidence from the original `rmmod` hang;
- the second reboot likely overwrote or displaced the hang evidence.

Logs:

- `logs/20260421T101631Z-pstore-after-double-reboot.log`
- `logs/20260421T101649Z-copy-pstore-after-double-reboot-retry.log`

## Timeline Evidence

- `last -x` shows current boot at `13:14`;
- it also shows a clean shutdown at `13:13`;
- an earlier session is marked `crash`, consistent with an abnormal reboot before the later clean reboot.

Log:

- `logs/20260421T101649Z-reboot-history-after-double-reboot.log`

## Latest rmmod Attempt

Latest rmmod trace:

- `logs/20260421T101016Z-rmmod-trace.log`

It contains:

- `starting live dmesg capture`
- `collecting pre-rmmod state`
- `running: rmmod nv_ov5647`

It does not contain `rmmod rc=...`, which confirms the command did not return.

The associated live dmesg log is empty:

- `logs/20260421T101016Z-rmmod-live-dmesg.log`

The pre-rmmod dmesg tail shows the loaded module was an older build:

- module init line only includes `register_i2c_driver=1 allow_hw_probe=1 skip_v4l2_register=0`;
- it does not include the new `skip_v4l2_unregister`, `split_v4l2_unregister`, or `unload_marker_delay_ms` parameters;
- therefore the latest hang did not test the newly built unregister diagnostics.

Analysis log:

- `logs/20260421T101712Z-rmmod-101016-analysis.log`
- `logs/20260421T101712Z-rmmod-101016-grep.log`

## Conclusion

- The hang is still consistent with the old full V4L2 unregister path.
- The accidental second reboot means current pstore is not sufficient to explain the hang at stack level.
- The system is now in a clean state with no `nv_ov5647` loaded.
- The next runtime test can load the rebuilt module, but it must be manual and one command at a time.

## Next Best Step

Manual load only, with split-unregister enabled from the start:

```bash
sudo /home/cam/ov5647_driver_codex/scripts/run_manual_insmod_diag.sh split-unregister
```

If that returns `insmod ok`, the next single test should be a V4L2 query or single-frame capture. Do not unload until the capture result is recorded.
