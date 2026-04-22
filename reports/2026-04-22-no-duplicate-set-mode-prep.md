# 2026-04-22 No Duplicate Set Mode Prep

## Summary

A source-side stream-start experiment was prepared after route A and route C both reached `VIDIOC_STREAMON` but delivered no frames.

The change removes the duplicate `ov5647_set_mode()` call from `ov5647_start_streaming()`. This avoids applying the full common/mode tables, including software reset `0x0103`, twice during a single capture start.

No module unload/load or capture was run by Codex.

## Rationale

Runtime logs show this sequence during capture:

```text
ov5647_set_mode: applying mode=0
ov5647_set_mode: mode applied, sensor remains in standby
ov5647_start_streaming: enter
ov5647_set_mode: applying mode=0
ov5647_set_mode: mode applied, sensor remains in standby
ov5647_start_streaming: exit success
```

Because `ov5647_common_regs` includes software reset `0x0103`, the second `set_mode()` inside `start_streaming()` re-applies reset and the full mode table immediately before stream enable. NVIDIA tegracam has already applied the mode before entering `start_streaming()`, so this duplicate programming is unnecessary and potentially disruptive.

## Source Change

Changed file:

- `src/nv_ov5647/nv_ov5647.c`

Change:

- removed the `ov5647_set_mode(tc_dev)` call from `ov5647_start_streaming()`;
- added a log marker:
  - `using mode already applied by tegracam set_mode`

The stream-start sequence now only writes:

- `OV5647_REG_MIPI_CTRL00`;
- `OV5647_REG_FRAME_OFF_NUMBER`;
- `OV5647_REG_MODE_SELECT = STREAMING`;
- `OV5640_REG_PAD_OUT = 0`.

## Build

Command:

```bash
./scripts/build_module.sh
```

Result:

- build passed;
- artifact: `artifacts/build/20260422T080544Z/nv_ov5647.ko`;
- new module `srcversion`: `E9CE1D1EF58B852F6484431`;
- currently loaded module at prep time: `2F4050CDED69B8A5FF0C49F`.

## Logs

- `logs/20260422T080544Z-build-module-no-duplicate-set-mode.log`
- `logs/20260422T080544Z-build_module.log`
- `logs/20260422T080548Z-diff-no-duplicate-set-mode.log`
- `logs/20260422T080548Z-modinfo-no-duplicate-set-mode.log`
- `logs/20260422T080548Z-artifact-cmp-no-duplicate-set-mode.log`

## Next Manual Runtime Test

The next commands are risky and must be run manually by the user, one at a time:

```bash
sudo /home/cam/ov5647_driver_codex/scripts/run_manual_rmmod_trace.sh
sudo /home/cam/ov5647_driver_codex/scripts/run_manual_insmod_diag.sh full-delay
sudo /home/cam/ov5647_driver_codex/scripts/run_manual_single_frame_trace.sh
```

Expected validation marker in dmesg:

```text
ov5647_start_streaming: using mode already applied by tegracam set_mode
```
