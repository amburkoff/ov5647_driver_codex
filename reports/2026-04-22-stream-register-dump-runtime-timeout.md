# 2026-04-22 Stream Register Dump Runtime Timeout

## Summary

The diagnostic stream-register dump was runtime-tested. Capture still timed out with a zero-byte raw file, but the register dump exposed a concrete driver defect.

Root-cause candidate: sensor output-enable registers are disabled after `set_mode()` and remain disabled after `STREAMON`.

## User-Run Commands

```bash
sudo /home/cam/ov5647_driver_codex/scripts/run_manual_rmmod_trace.sh
sudo /home/cam/ov5647_driver_codex/scripts/run_manual_insmod_diag.sh full-delay-dump
sudo /home/cam/ov5647_driver_codex/scripts/run_manual_single_frame_trace.sh
```

## Runtime Identity

- `rmmod rc=0`;
- `insmod rc=0`;
- loaded module `srcversion`: `E6D2A445F8276648D752078`;
- `dump_stream_regs=1`;
- active route: route C dev overlay.

## Capture Result

```text
VIDIOC_STREAMON returned 0 (Success)
capture rc=124
raw size=0 bytes
```

Raw artifact:

- `artifacts/captures/20260422T081515Z/ov5647-640x480-bg10.raw`
- size: `0` bytes

## Key Register Evidence

At `power_on_lp11`, sensor output-enable registers are enabled:

```text
0x3000 = 0x0f
0x3001 = 0xff
0x3002 = 0xe4
0x300d = 0x01
0x0100 = 0x00
0x4800 = 0x25
```

At `after_set_mode`, the common/mode programming has disabled output again:

```text
0x3000 = 0x00
0x3001 = 0x00
0x3002 = 0x00
0x300d = 0x00
0x0100 = 0x00
0x4800 = 0x34
```

At `after_stream_on`, the sensor enters streaming but output-enable is still disabled:

```text
0x0100 = 0x01
0x3000 = 0x00
0x3001 = 0x00
0x3002 = 0x00
0x300d = 0x00
0x4800 = 0x34
```

VI still reports:

```text
uncorr_err: request timed out after 2500 ms
```

## Interpretation

The previous output-enable fix was placed in `power_on()`, but `ov5647_common_regs` later writes:

```text
0x3000 = 0x00
0x3001 = 0x00
0x3002 = 0x00
```

That means the driver successfully powers the sensor and enables output, then disables output again during mode programming. `start_streaming()` currently does not re-enable those registers, so CSI data may never leave the sensor even though `0x0100 = 0x01`.

## Next Source Change

Re-enable the OV5647 sensor output table after mode programming and before/around stream start. This is a single-variable driver fix and does not require DT or reboot changes.

## Logs

- `logs/20260422T081451Z-rmmod-trace.log`
- `logs/20260422T081507Z-manual-insmod-full-delay-dump.log`
- `logs/20260422T081507Z-manual-insmod-full-delay-dump.dmesg-tail.log`
- `logs/20260422T081507Z-manual-insmod-full-delay-dump.modinfo.log`
- `logs/20260422T081515Z-single-frame-trace.log`
- `logs/20260422T081515Z-stream-live-dmesg.log`
- `logs/20260422T081515Z-single-frame-post-dmesg-tail.log`
- `logs/20260422T081650Z-list-081x-logs.log`
- `logs/20260422T081650Z-grep-dump-run-identity.log`
- `logs/20260422T081650Z-grep-stream-dump-capture.log`
- `logs/20260422T081650Z-capture-artifact-size.log`
