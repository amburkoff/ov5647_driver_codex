# Frank-s15 Route-A Capture Timeout

Date: 2026-04-23

## Context

- Camera/ribbon: alternate OV5647 on Jetson `cam0`, longer ribbon marked `Frank-s15-v1.0`.
- Active boot profile: `boot_profile=ov5647-dev`.
- Active live DT route: route A, `ov5647_a@36`, `serial_b`, `port-index = 1`, `lane_polarity = 6`.
- Driver source variant: mainline VGA timing bit diagnostic, `0x3821 = 0x03`.
- Loaded module `srcversion`: `632487CC0794D5D198269C9`.
- Manual load profile: `full-delay-dump-contclk-mclk24`.

## Result

- Capture timestamp: `20260423T075323Z`.
- Capture command reached `VIDIOC_STREAMON returned 0`.
- Capture returned `rc=124`.
- Raw output: `artifacts/captures/20260423T075323Z/ov5647-640x480-bg10.raw`.
- Raw size: `0 bytes`.
- RTCPU/NVCSI trace directory: `artifacts/traces/20260423T075323Z`.
- Dmesg log: `logs/20260423T075323Z-single-frame-rtcpu-live-dmesg.log`.

## Evidence

- Probe succeeded and chip ID remained `0x5647`.
- MCLK enabled at `24000000`.
- Stream state readback after mode/stream:
  - `0x0100 = 0x01`;
  - `0x3000 = 0x0f`;
  - `0x3001 = 0xff`;
  - `0x3002 = 0xe4`;
  - `0x3821 = 0x03`;
  - `0x4800 = 0x04`.
- VI reported repeated `uncorr_err: request timed out after 2500 ms`.
- RTCPU trace events were enabled but contained no runtime SOF/EOF/NVCSI/vinotify event.

## Interpretation

Changing the camera/ribbon to `Frank-s15-v1.0` and testing the mainline `0x3821 = 0x03` VGA variant did not resolve the no-SOF condition.

The active route-A DT still declares `discontinuous_clk = "yes"`, while this test forced sensor-side continuous clock through `continuous_mipi_clock=1`, producing `0x4800 = 0x04`. The next minimal software experiment is to retest route A with sensor-side non-continuous clock (`0x4800 = 0x34`) while keeping MCLK at 24 MHz and all other variables unchanged.

## Next Manual Test

After unloading the currently loaded module manually:

```bash
sudo /home/cam/ov5647_driver_codex/scripts/run_manual_insmod_diag.sh full-delay-dump-mclk24
sudo /home/cam/ov5647_driver_codex/scripts/run_manual_single_frame_rtcpu_trace.sh
```

Run the capture only if the insmod command reports `insmod rc=0`.
