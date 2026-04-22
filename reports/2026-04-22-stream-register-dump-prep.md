# 2026-04-22 Stream Register Dump Prep

## Summary

A diagnostic-only OV5647 register readback path was added to inspect sensor state around mode programming and stream start.

No risky module reload, unload, capture, or reboot was run by Codex.

## Source Change

Changed files:

- `src/nv_ov5647/nv_ov5647.c`
- `scripts/run_manual_insmod_diag.sh`

Driver change:

- added module parameter `dump_stream_regs`;
- default is `false`;
- when enabled, the driver reads and logs key OV5647 registers at:
  - `power_on_lp11`;
  - `after_set_mode`;
  - `after_stream_on`.

Registers include:

- `0x0100` mode select;
- `0x0103` software reset;
- `0x3000`/`0x3001`/`0x3002` sensor output-enable state;
- `0x300d` pad output;
- `0x3016`/`0x3017`/`0x3018` MIPI control;
- `0x3034`/`0x3035`/`0x3036`/`0x303c` PLL state;
- `0x3808`-`0x380f` output size and HTS/VTS;
- `0x3820`/`0x3821` timing format;
- `0x4202` frame-off number;
- `0x4800` MIPI control;
- `0x4814` virtual-channel control.

Script change:

- added manual insmod profile `full-delay-dump`;
- this profile uses:

```text
register_i2c_driver=1 allow_hw_probe=1 dump_stream_regs=1 unload_marker_delay_ms=500
```

## Build

Command:

```bash
./scripts/build_module.sh
```

Result:

- build passed;
- artifact: `artifacts/build/20260422T081242Z/nv_ov5647.ko`;
- module `srcversion`: `E6D2A445F8276648D752078`;
- `modinfo` shows `dump_stream_regs` as a module parameter.

## Static Checks

- `bash -n scripts/run_manual_insmod_diag.sh`: passed.
- marker check confirms the new strings exist in the built `.ko`.

## Logs

- `logs/20260422T081250Z-build-module-stream-reg-dump.log`
- `logs/20260422T081242Z-build_module.log`
- `logs/20260422T081246Z-modinfo-stream-reg-dump.log`
- `logs/20260422T081246Z-diff-stream-reg-dump.log`
- `logs/20260422T081330Z-clean-marker-check-stream-reg-dump.log`
- `logs/20260422T081246Z-script-syntax-stream-reg-dump.log`

## Next Manual Runtime Test

The next commands are risky and must be run manually by the user, one at a time:

```bash
sudo /home/cam/ov5647_driver_codex/scripts/run_manual_rmmod_trace.sh
sudo /home/cam/ov5647_driver_codex/scripts/run_manual_insmod_diag.sh full-delay-dump
sudo /home/cam/ov5647_driver_codex/scripts/run_manual_single_frame_trace.sh
```

Expected dmesg markers:

```text
nv_ov5647: diagnostics dump_stream_regs=1
ov5647_dump_stream_regs: begin phase=power_on_lp11
ov5647_dump_stream_regs: begin phase=after_set_mode
ov5647_dump_stream_regs: begin phase=after_stream_on
```

No reboot is needed.
