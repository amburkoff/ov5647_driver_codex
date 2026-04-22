# 2026-04-22 Output Enable Restore Fix

## Summary

A minimal source-side fix was prepared after the stream-register dump showed that `0x3000/0x3001/0x3002` are disabled after mode programming and remain disabled after `STREAMON`.

No module reload, unload, capture, or reboot was run by Codex.

## Source Change

Changed file:

- `src/nv_ov5647/nv_ov5647.c`

Change:

- restore `ov5647_sensor_oe_enable_regs` after mode programming;
- restore `ov5647_sensor_oe_enable_regs` again immediately before stream-on as a safety net;
- add explicit logs:
  - `sensor output-enable restored after mode programming`;
  - `sensor output-enable restored before stream`.

Expected register effect when tested with `dump_stream_regs=1`:

- `after_set_mode` should show:
  - `0x3000 = 0x0f`;
  - `0x3001 = 0xff`;
  - `0x3002 = 0xe4`;
- `after_stream_on` should also show the same values with `0x0100 = 0x01`.

## Build

Command:

```bash
./scripts/build_module.sh
```

Result:

- build passed;
- artifact: `artifacts/build/20260422T081812Z/nv_ov5647.ko`;
- module `srcversion`: `96FCD7FB15E34D8DE37E4F2`;
- marker check confirms the new output-restore log strings are present in the built `.ko`.

## Logs

- `logs/20260422T081812Z-build_module.log`
- `logs/20260422T081825Z-build-module-output-restore-after-mode.log`
- `logs/20260422T081820Z-modinfo-output-restore-after-mode.log`
- `logs/20260422T081820Z-diff-output-restore-after-mode.log`
- `logs/20260422T081820Z-marker-check-output-restore-after-mode.log`
- `logs/20260422T081820Z-git-status-output-restore-after-mode.log`

## Next Manual Runtime Test

The next commands are risky and must be run manually by the user, one at a time:

```bash
sudo /home/cam/ov5647_driver_codex/scripts/run_manual_rmmod_trace.sh
sudo /home/cam/ov5647_driver_codex/scripts/run_manual_insmod_diag.sh full-delay-dump
sudo /home/cam/ov5647_driver_codex/scripts/run_manual_single_frame_trace.sh
```

No reboot is needed.
