# 2026-04-22 Output Enable Restore Runtime Timeout

## Summary

The output-enable restore fix was runtime-tested. The fix worked at the register level, but capture still timed out with no frame data.

Result: the previous `0x3000/0x3001/0x3002` defect is fixed, but it is not the only blocker for CSI frame delivery.

## User-Run Commands

```bash
sudo /home/cam/ov5647_driver_codex/scripts/run_manual_rmmod_trace.sh
sudo /home/cam/ov5647_driver_codex/scripts/run_manual_insmod_diag.sh full-delay-dump
sudo /home/cam/ov5647_driver_codex/scripts/run_manual_single_frame_trace.sh
```

## Runtime Identity

- `rmmod rc=0`;
- `insmod rc=0`;
- loaded module `srcversion`: `96FCD7FB15E34D8DE37E4F2`;
- `dump_stream_regs=1`;
- active route: route C dev overlay.

## Capture Result

```text
VIDIOC_STREAMON returned 0 (Success)
capture rc=124
raw size=0 bytes
```

Raw artifact:

- `artifacts/captures/20260422T081948Z/ov5647-640x480-bg10.raw`
- size: `0` bytes

## Register Evidence

The output-enable restore fix executed:

```text
ov5647_set_mode: sensor output-enable restored after mode programming
ov5647_start_streaming: sensor output-enable restored before stream
```

At `after_set_mode`, output-enable is now restored:

```text
0x0100 = 0x00
0x3000 = 0x0f
0x3001 = 0xff
0x3002 = 0xe4
0x4800 = 0x34
```

At `after_stream_on`, the sensor is in streaming and output-enable remains restored:

```text
0x0100 = 0x01
0x3000 = 0x0f
0x3001 = 0xff
0x3002 = 0xe4
0x4800 = 0x34
```

VI still reports:

```text
uncorr_err: request timed out after 2500 ms
```

## Interpretation

This closes one real driver bug: the sensor is no longer left with output disabled after mode programming. Since no frame is still delivered, the remaining blocker is likely in one of:

- MIPI stream-start register details;
- CSI/VI DT timing mismatch;
- lane polarity / physical lane mapping / Raspberry Pi cable-adapter compatibility;
- incomplete sensor mode values not included in the current diagnostic dump.

The next source-side experiment should stay narrow and compare MIPI stream-start sequencing with upstream OV5647 references before changing DT again.

## Logs

- `logs/20260422T081932Z-rmmod-trace.log`
- `logs/20260422T081942Z-manual-insmod-full-delay-dump.log`
- `logs/20260422T081942Z-manual-insmod-full-delay-dump.dmesg-tail.log`
- `logs/20260422T081942Z-manual-insmod-full-delay-dump.modinfo.log`
- `logs/20260422T081948Z-single-frame-trace.log`
- `logs/20260422T081948Z-stream-live-dmesg.log`
- `logs/20260422T081948Z-single-frame-post-dmesg-tail.log`
- `logs/20260422T082110Z-list-0819-logs.log`
- `logs/20260422T082110Z-identity-output-restore-runtime.log`
- `logs/20260422T082110Z-stream-reg-output-restore-runtime.log`
- `logs/20260422T082110Z-output-restore-capture-artifact-size.log`
