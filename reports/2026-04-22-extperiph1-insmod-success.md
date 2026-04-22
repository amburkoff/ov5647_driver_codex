# Extperiph1 Insmod Success - 2026-04-22

## Result

Manual module load after the corrected DT clock binding succeeded:

- command: `sudo /home/cam/ov5647_driver_codex/scripts/run_manual_insmod_diag.sh full-delay-dump-contclk-mclk24`
- log timestamp: `20260422T135306Z`
- result: `insmod rc=0`

## Clock Verification

Driver logs now show the intended camera MCLK path:

- `mclk get ok name=extperiph1 current_rate=51000000`
- `enabling mclk def_clk_freq=24000000 current_rate=51000000`
- `mclk enabled rate=24000000`

Debugfs also confirms:

- `extperiph1 rate=24000000`
- `aud_mclk rate=45158398`

This confirms the previous `0x07` clock binding bug is fixed for the live route-C overlay.

## Media State

- `/dev/video0` exists.
- `media-ctl -p` shows an enabled path:
  - `nv_ov5647 9-0036`
  - `13e00000.host1x:nvcsi@15a00000-`
  - `vi-output, nv_ov5647 9-0036`

## Logs

- `logs/20260422T135306Z-manual-insmod-full-delay-dump-contclk-mclk24.log`
- `logs/20260422T135306Z-manual-insmod-full-delay-dump-contclk-mclk24.dmesg-tail.log`
- `logs/20260422T135335Z-analyze-extperiph1-insmod-mclk-rate.log`
- `logs/20260422T135335Z-clock-debugfs-after-extperiph1-insmod.log`
- `logs/20260422T135335Z-runtime-state-after-extperiph1-insmod.log`

## Next Step

Manual-only capture test:

```bash
sudo /home/cam/ov5647_driver_codex/scripts/run_manual_single_frame_rtcpu_trace.sh
```

If this still returns `rc=124` and zero bytes, the clock root cause is closed and the next focus is physical CSI lane/cable/adapter compatibility.
