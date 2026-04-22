# 2026-04-22 Continuous MIPI Clock Runtime Timeout

## Summary

The continuous MIPI clock diagnostic path was runtime-tested. The new stream-on value was applied correctly, but capture still timed out with a zero-byte raw file.

Result: switching `0x4800` from `0x34` to upstream-default `0x04` is not sufficient to restore CSI frame delivery.

## User-Run Commands

```bash
sudo /home/cam/ov5647_driver_codex/scripts/run_manual_rmmod_trace.sh
sudo /home/cam/ov5647_driver_codex/scripts/run_manual_insmod_diag.sh full-delay-dump-contclk
sudo /home/cam/ov5647_driver_codex/scripts/run_manual_single_frame_trace.sh
```

## Runtime Identity

- `rmmod rc=0`;
- `insmod rc=0`;
- loaded module `srcversion`: `92FD1291C5FC74E28DC6E26`;
- `dump_stream_regs=1`;
- `continuous_mipi_clock=1`;
- active route: route C dev overlay.

## Capture Result

```text
VIDIOC_STREAMON returned 0 (Success)
capture rc=124
raw size=0 bytes
```

Raw artifact:

- `artifacts/captures/20260422T082520Z/ov5647-640x480-bg10.raw`
- size: `0` bytes

## Register Evidence

The continuous-clock diagnostic path executed:

```text
ov5647_start_streaming: mipi_ctrl00 stream value=0x04 continuous_mipi_clock=1
```

At `after_stream_on`:

```text
0x0100 = 0x01
0x3000 = 0x0f
0x3001 = 0xff
0x3002 = 0xe4
0x4800 = 0x04
```

VI still reports:

```text
uncorr_err: request timed out after 2500 ms
```

## Interpretation

The simple MIPI clock-mode hypothesis is now tested:

- non-continuous-style local value `0x4800=0x34` timed out;
- upstream-default continuous value `0x4800=0x04` also timed out;
- output-enable remains restored in both cases.

The remaining highest-risk area is no longer a single stream-start bit. It is now more likely one of:

- DT timing values seen by the Jetson camera framework;
- CSI lane polarity / lane ordering / physical FFC adapter compatibility;
- missing sensor registers outside the current 640x480 minimal table;
- mismatch between active DT route C and the actual MIPI lane path on the CBL carrier.

## Logs

- `logs/20260422T082504Z-rmmod-trace.log`
- `logs/20260422T082514Z-manual-insmod-full-delay-dump-contclk.log`
- `logs/20260422T082514Z-manual-insmod-full-delay-dump-contclk.dmesg-tail.log`
- `logs/20260422T082514Z-manual-insmod-full-delay-dump-contclk.modinfo.log`
- `logs/20260422T082520Z-single-frame-trace.log`
- `logs/20260422T082520Z-stream-live-dmesg.log`
- `logs/20260422T082520Z-single-frame-post-dmesg-tail.log`
- `logs/20260422T082700Z-list-0825-logs.log`
- `logs/20260422T082700Z-identity-contclk-runtime.log`
- `logs/20260422T082700Z-stream-reg-contclk-runtime.log`
- `logs/20260422T082700Z-contclk-capture-artifact-size.log`
