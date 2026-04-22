# MCLK Diagnostic Prep - 2026-04-22

## Context

The current route-C continuous-clock runtime path reaches `VIDIOC_STREAMON` but produces no frame data. RTCPU/NVCSI tracing showed no SOF, no EOF, no NVCSI interrupt, and no RTCPU exception during the capture timeout. This points to no valid CSI signal reaching NVCSI/VI, but MCLK must be excluded before treating the issue as primarily physical route/cable/adapter mapping.

## What Changed

- Added driver logs for the DT-derived MCLK frequency and effective `clk_get_rate()` before/after `camera_common_mclk_enable()`.
- Added diagnostic-only module parameter `mclk_override_hz`, default `0`.
- Added manual insmod profile `full-delay-dump-contclk-mclk24`, which passes `mclk_override_hz=24000000`.
- No runtime load/unload/streaming command was run by Codex.

## Files Changed

- `src/nv_ov5647/nv_ov5647.c`
- `scripts/run_manual_insmod_diag.sh`
- `docs/10-results-and-status.md`
- `docs/11-known-issues.md`
- `reports/2026-04-22-mclk-diagnostic-prep.md`

## Commands Run

- `sed`/`grep` inspection of NVIDIA r36.5 `camera_common.c` and `tegracam_core.c`
- `bash -n scripts/run_manual_insmod_diag.sh`
- `./scripts/build_module.sh`
- `modinfo src/nv_ov5647/nv_ov5647.ko`

## Logs

- `logs/20260422T133240Z-inspect-camera-common-mclk-enable.log`
- `logs/20260422T133254Z-inspect-def-clk-freq-parsing.log`
- `logs/20260422T133311Z-inspect-dt-mode-mclk-freq-live.log`
- `logs/20260422T133427Z-build-module-mclk-diagnostic.log`
- `logs/20260422T133437Z-modinfo-mclk-diagnostic.log`

## Result

- Build passed.
- `modinfo` confirms `mclk_override_hz` is present.
- NVIDIA r36.5 code confirms active MCLK should be set from DT `mclk_khz`; live route-C DT says `mclk_khz = "24000"`.

## Next Step

Manual-only risky runtime test:

```bash
sudo /home/cam/ov5647_driver_codex/scripts/run_manual_insmod_diag.sh full-delay-dump-contclk-mclk24
sudo /home/cam/ov5647_driver_codex/scripts/run_manual_single_frame_rtcpu_trace.sh
```

If this still gives no SOF and zero-byte raw output, the next best step is hardware route verification: CLB/makerobo camera connector pinout, cable side/orientation, and Raspberry Pi Zero-style 22-pin module compatibility with the Jetson 22-pin connector.
