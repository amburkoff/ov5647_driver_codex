# 2026-04-22 Extperiph1 Capture Timeout

## Summary

Route C now uses the corrected Tegra234 `TEGRA234_CLK_EXTPERIPH1` BPMP clock ID and the driver confirms active 24 MHz MCLK, but single-frame capture still times out with zero bytes and no RTCPU/NVCSI SOF evidence.

## Evidence

- Manual insmod profile `full-delay-dump-contclk-mclk24` succeeded at `20260422T135306Z`.
- Driver logs confirm `ov5647_power_on: mclk enabled rate=24000000`.
- Manual capture `20260422T135523Z` reached `VIDIOC_STREAMON returned 0`.
- Capture exited by timeout with `rc=124`.
- Raw output file is zero bytes:
  - `artifacts/captures/20260422T135523Z/ov5647-640x480-bg10.raw`
- RTCPU trace has stream setup/enable events but no runtime SOF/NVCSI interrupt/vinotify error events.

## Interpretation

The previous wrong-clock defect was real and is now fixed on route C. It does not explain the remaining no-SOF failure by itself.

The leading suspects are now:

- physical CLB/makerobo connector-to-CSI route mismatch;
- FFC/adaptor pinout or orientation mismatch for the Raspberry Pi-style `JT-ZERO-V2.0 YH` OV5647 modules;
- route A still untested with the corrected `extperiph1` clock binding.

## Next Step

Prepare route A with the corrected `TEGRA234_CLK_EXTPERIPH1` clock ID and stage it as the dev overlay. This requires a reboot because the active DT overlay changes. No risky module or streaming commands should be run by Codex.

After reboot, verify live DT first, then ask the user to run the same manual insmod and RTCPU capture scripts.

## Logs

- `logs/20260422T135306Z-manual-insmod-full-delay-dump-contclk-mclk24.log`
- `logs/20260422T135306Z-manual-insmod-full-delay-dump-contclk-mclk24.dmesg-tail.log`
- `logs/20260422T135523Z-single-frame-rtcpu-live-dmesg.log`
- `logs/20260422T135523Z-single-frame-rtcpu-trace.log`
- `logs/20260422T135631Z-analyze-extperiph1-capture-timeout.log`
- `logs/20260422T135631Z-compare-before-after-rtcpu-traces-no-sof.log`
