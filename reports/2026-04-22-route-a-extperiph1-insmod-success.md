# 2026-04-22 Route A Extperiph1 Insmod Success

## Summary

Manual route-A module load succeeded after rebooting into the corrected `TEGRA234_CLK_EXTPERIPH1` overlay. The route-A path now reaches chip ID, 24 MHz MCLK, `/dev/video0`, and an enabled media graph.

## Manual Command

The user ran:

```bash
sudo /home/cam/ov5647_driver_codex/scripts/run_manual_insmod_diag.sh full-delay-dump-contclk-mclk24
```

Result:

- `insmod rc=0`.

## Verified

- Active route: route A.
- I2C client: `nv_ov5647 9-0036`.
- Parsed GPIO: `pwdn_gpio=397`.
- Parsed clock: `mclk=extperiph1`.
- Active MCLK during power-on: `24000000`.
- Chip ID: `0x5647`.
- Module parameters:
  - `dump_stream_regs=Y`;
  - `continuous_mipi_clock=Y`;
  - `mclk_override_hz=24000000`.
- `/dev/video0` exists.
- `/dev/v4l-subdev0` and `/dev/v4l-subdev1` exist.
- Media graph links are enabled from sensor to NVCSI to VI.
- `v4l2-ctl --list-formats-ext` reports `BG10` at `640x480`, `30 fps`.

## Next Step

Run one manual RTCPU/NVCSI traced capture. This is risky enough that Codex should not execute it directly.

Expected command:

```bash
sudo /home/cam/ov5647_driver_codex/scripts/run_manual_single_frame_rtcpu_trace.sh
```

If route A still returns timeout and zero bytes, route A and route C will both have failed after the corrected clock-ID work. That would make physical connector/cable/adaptor compatibility the main root-cause track.

## Logs

- `logs/20260422T140729Z-manual-insmod-full-delay-dump-contclk-mclk24.log`
- `logs/20260422T140800Z-route-a-after-manual-insmod-dmesg.log`
- `logs/20260422T140800Z-route-a-after-manual-insmod-v4l2-media.log`
- `logs/20260422T140800Z-route-a-after-manual-insmod-clock-route-state.log`
- `logs/20260422T140815Z-route-a-after-manual-insmod-v4l2-query.log`
