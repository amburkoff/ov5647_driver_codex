# 2026-04-22 Route-C Continuous Clock Runtime Timeout

## Summary

The matched continuous-clock experiment was runtime-tested after reboot:

- receiver-side DT: `discontinuous_clk = "no"`;
- sensor-side stream setting: `continuous_mipi_clock=1`, readback `0x4800=0x04`.

The capture still timed out with zero bytes.

## User-Run Command

```bash
sudo /home/cam/ov5647_driver_codex/scripts/run_manual_single_frame_trace.sh
```

The module was already loaded before this command.

## Runtime Identity

- active boot profile: `boot_profile=ov5647-dev`;
- route: route C;
- live DT: `serial_c`, `port-index=2`, `bus-width=2`, `lane_polarity="0"`, `discontinuous_clk="no"`;
- loaded module `srcversion`: `92FD1291C5FC74E28DC6E26`;
- module params:
  - `continuous_mipi_clock=Y`;
  - `dump_stream_regs=Y`;
  - `allow_hw_probe=Y`;
  - `register_i2c_driver=Y`.

## Capture Result

```text
VIDIOC_STREAMON returned 0 (Success)
capture rc=124
raw size=0 bytes
```

Raw artifact:

- `artifacts/captures/20260422T085016Z/ov5647-640x480-bg10.raw`

## Register Evidence

After stream-on:

```text
0x0100 = 0x01
0x3000 = 0x0f
0x3001 = 0xff
0x3002 = 0xe4
0x3808/0x3809 = 0x0280
0x380a/0x380b = 0x01e0
0x380c/0x380d = 0x073c
0x380e/0x380f = 0x01f8
0x4800 = 0x04
```

VI still reports:

```text
uncorr_err: request timed out after 2500 ms
```

## Interpretation

The simple sensor/receiver clock-mode mismatch hypothesis is now tested and not sufficient:

- previous run: sensor `0x4800=0x04`, live DT still `discontinuous_clk="yes"`, timed out;
- this run: sensor `0x4800=0x04`, live DT `discontinuous_clk="no"`, still timed out.

Current highest-value next diagnostic is RTCPU/NVCSI tracing around STREAMON to distinguish:

- no MIPI activity at all;
- NVCSI lane/PHY/deskew errors;
- VI channel configuration issue;
- frame start without frame end;
- physical cable/adapter/lane mapping problem.

## Prepared Next Tool

Added:

- `scripts/run_manual_single_frame_rtcpu_trace.sh`

The user should run it manually because it performs a capture/STREAMON operation:

```bash
sudo /home/cam/ov5647_driver_codex/scripts/run_manual_single_frame_rtcpu_trace.sh
```

## Logs

- `logs/20260422T085016Z-single-frame-trace.log`
- `logs/20260422T085016Z-stream-live-dmesg.log`
- `logs/20260422T085016Z-single-frame-post-dmesg-tail.log`
- `logs/20260422T085123Z-inspect-085016-capture.log`
- `logs/20260422T085123Z-module-state-after-085016-capture.log`
- `logs/20260422T085123Z-capture-size-085016.log`
- `logs/20260422T085147Z-v4l2-query-after-085016-contclk-timeout.log`
- `logs/20260422T085147Z-media-ctl-after-085016-contclk-timeout.log`
- `logs/20260422T085147Z-dmesg-tail-after-085016-contclk-timeout.log`
- `logs/20260422T085147Z-live-dt-fields-after-085016-contclk-timeout.log`
