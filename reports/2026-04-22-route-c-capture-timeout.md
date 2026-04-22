# 2026-04-22 Route-C Capture Timeout

## Summary

Manual single-frame capture on the route-C overlay reached `VIDIOC_STREAMON`, but no frame data was delivered. The raw output file is zero bytes and VI reported repeated capture timeouts.

Result: route C behaves like route A for the current driver/mode: probe succeeds, `/dev/video0` exists, but CSI frames do not arrive.

## User-Run Command

```bash
sudo /home/cam/ov5647_driver_codex/scripts/run_manual_single_frame_trace.sh
```

## Capture Result

```text
VIDIOC_REQBUFS returned 0 (Success)
VIDIOC_QUERYBUF returned 0 (Success)
VIDIOC_QBUF returned 0 (Success)
VIDIOC_STREAMON returned 0 (Success)
capture rc=124
raw size=0 bytes
```

Raw artifact:

- `artifacts/captures/20260422T080247Z/ov5647-640x480-bg10.raw`
- size: `0` bytes

## Runtime Identity

- boot profile: `ov5647-dev`;
- active route: route C;
- video node: `platform:tegra-capture-vi:2`;
- loaded module `srcversion`: `2F4050CDED69B8A5FF0C49F`;
- V4L2 format: `BG10 640x480`;
- media graph links remained enabled after timeout.

## Kernel Log Summary

Driver path:

- `ov5647_power_on`: success;
- `stream-stop LP-11 setup complete`;
- `ov5647_set_mode`: success;
- `ov5647_start_streaming`: success;
- `ov5647_stop_streaming`: success after timeout cleanup;
- `ov5647_power_off`: success.

VI errors:

- repeated `tegra-camrtc-capture-vi ... uncorr_err: request timed out after 2500 ms`.

## Interpretation

Both route A and route C now show the same behavior:

- I2C works;
- chip ID reads as `0x5647`;
- tegracam/V4L2/media registration works;
- STREAMON callback returns success;
- VI receives no frame.

This lowers the probability that the primary issue is the selected p3768 A/C route. The next source-side focus should be the stream-start/mode timing path and DT timing consistency rather than another connector swap.

## Logs

- `logs/20260422T080247Z-single-frame-trace.log`
- `logs/20260422T080247Z-stream-live-dmesg.log`
- `logs/20260422T080247Z-single-frame-post-dmesg-tail.log`
- `logs/20260422T080357Z-after-route-c-capture-timeout-state.log`
- `logs/20260422T080357Z-route-c-capture-timeout-live-dmesg-summary.log`
- `logs/20260422T080357Z-route-c-capture-timeout-post-dmesg-summary.log`
- `logs/20260422T080357Z-after-route-c-capture-timeout-v4l2-media.log`

## Next Step

Prepare one source-side experiment at a time. The next candidate is to align stream-start and timing more tightly with upstream OV5647 behavior, then rebuild and ask the user to manually unload/load/capture again.
