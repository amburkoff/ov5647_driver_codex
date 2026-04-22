# 2026-04-22 Continuous MIPI Clock Prep

## Summary

A diagnostic stream-start experiment was prepared after the output-enable restore fix proved that output is enabled but VI still receives no frames.

No module unload, load, capture, or reboot was run by Codex.

## Rationale

The current driver has been writing `0x4800 = 0x34` on stream start. Upstream Linux OV5647 uses:

- `0x4800 = 0x04` by default;
- `0x4800 = 0x34` only when non-continuous clock mode is enabled.

The current DT does not establish that non-continuous clock mode is required for this CLB route. This experiment tests the upstream default continuous-clock stream-on value without changing the default driver behavior.

Reference fetched and stored locally:

- `artifacts/reference/upstream-linux-ov5647.c`

## Source Change

Changed files:

- `src/nv_ov5647/nv_ov5647.c`
- `scripts/run_manual_insmod_diag.sh`

Driver change:

- added module parameter `continuous_mipi_clock`, default `false`;
- when `continuous_mipi_clock=1`, stream-on writes `OV5647_REG_MIPI_CTRL00 = 0x04`;
- default remains the existing `0x34` path;
- added explicit log:
  - `mipi_ctrl00 stream value=0x%02x continuous_mipi_clock=%d`.

Script change:

- added manual profile `full-delay-dump-contclk`;
- this profile uses:

```text
register_i2c_driver=1 allow_hw_probe=1 dump_stream_regs=1 continuous_mipi_clock=1 unload_marker_delay_ms=500
```

## Build

Command:

```bash
./scripts/build_module.sh
```

Result:

- build passed;
- artifact: `artifacts/build/20260422T082312Z/nv_ov5647.ko`;
- module `srcversion`: `92FD1291C5FC74E28DC6E26`;
- `modinfo` shows `continuous_mipi_clock` as a module parameter.

## Logs

- `logs/20260422T082315Z-fetch-upstream-linux-ov5647.log`
- `logs/20260422T082315Z-upstream-ov5647-stream-grep.log`
- `logs/20260422T082325Z-upstream-ov5647-stream-snippet.log`
- `logs/20260422T082325Z-upstream-ov5647-clock-noncontinuous.log`
- `logs/20260422T082312Z-build_module.log`
- `logs/20260422T082505Z-build-module-continuous-mipi-clock.log`
- `logs/20260422T082320Z-modinfo-continuous-mipi-clock.log`
- `logs/20260422T082320Z-diff-continuous-mipi-clock.log`
- `logs/20260422T082320Z-marker-check-continuous-mipi-clock.log`
- `logs/20260422T082320Z-script-check-continuous-mipi-clock.log`

## Next Manual Runtime Test

The next commands are risky and must be run manually by the user, one at a time:

```bash
sudo /home/cam/ov5647_driver_codex/scripts/run_manual_rmmod_trace.sh
sudo /home/cam/ov5647_driver_codex/scripts/run_manual_insmod_diag.sh full-delay-dump-contclk
sudo /home/cam/ov5647_driver_codex/scripts/run_manual_single_frame_trace.sh
```

Expected readback if the new path is active:

```text
continuous_mipi_clock=1
mipi_ctrl00 stream value=0x04
phase=after_stream_on reg=0x4800 name=mipi_ctrl00 val=0x04
```

No reboot is needed.
