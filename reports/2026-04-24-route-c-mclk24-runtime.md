# Route-C MCLK24 Runtime Retest

Date: 2026-04-24

## Goal

Close the remaining focused software-only `25000 vs 24000` MCLK-intent
hypothesis on the canonical route-C baseline.

## Preconditions

- boot profile: `ov5647-dev`
- live DT:
  - `cam_i2cmux/i2c@1/ov5647_c@36`
  - `serial_c`
  - `port-index = 2`
  - `num_lanes = 2`
  - `mclk_khz = 24000`
  - `mclk_multiplier = 2.43`
  - `discontinuous_clk = yes`
  - `cil_settletime = 0`
- module not loaded before manual test

## Commands

```bash
sudo /home/cam/ov5647_driver_codex/scripts/run_manual_insmod_diag.sh full-delay-dump
sudo /home/cam/ov5647_driver_codex/scripts/run_manual_single_frame_rtcpu_trace.sh
```

## Runtime Artifacts

- insmod logs:
  - `logs/20260424T132045Z-manual-insmod-full-delay-dump.log`
  - `logs/20260424T132045Z-manual-insmod-full-delay-dump.modinfo.log`
  - `logs/20260424T132045Z-manual-insmod-full-delay-dump.dmesg-tail.log`
- traced capture:
  - `artifacts/traces/20260424T132054Z/`
  - `logs/20260424T132054Z-single-frame-rtcpu-live-dmesg.log`

## Result

- `insmod rc=0`
- `VIDIOC_STREAMON returned 0 (Success)`
- capture timeout `rc=124`
- raw output size `0 bytes`

## Receiver-Side Observations

- driver still logged:
  - `ov5647_power_on: mclk enabled rate=24000000`
- VI still logged repeated:
  - `uncorr_err: request timed out after 2500 ms`
- trace still showed only control-path activity:
  - `tegra_channel_capture_setup`
  - `capture_ivc_send/recv`
  - `tegra_channel_set_stream`
- trace still did **not** show:
  - `capture_event_sof`
  - `capture_event_eof`
  - `rtcpu_nvcsi_intr`
  - `vi_frame_begin`
  - `vi_frame_end`

## Conclusion

The controlled route-C `mclk24` retest did not change the failure class.

Aligning the DT intent from `mclk_khz=25000` to `mclk_khz=24000` on the
canonical route-C baseline still results in:

- stream-on success on the sensor/control side;
- receiver clocks and capture setup on the Jetson side;
- but no observable CSI frame ingress into `NVCSI/VI`.

This further weakens the remaining software-only MCLK-intent hypothesis.
