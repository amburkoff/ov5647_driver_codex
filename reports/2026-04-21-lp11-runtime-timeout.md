# 2026-04-21 LP-11 Runtime Timeout

## Context

- Runtime commands were executed manually by the user.
- Codex did not run `insmod`, `rmmod`, capture, stream, or reboot.
- Tested commit:
  - `211e879 driver: force ov5647 lanes to lp11 on power on`

## Manual Sequence

The user reported:

```text
rmmod ok
insmod ok
sudo /home/cam/ov5647_driver_codex/scripts/run_manual_single_frame_trace.sh
```

The LP-11 fixed module loaded and registered `/dev/video0`.

## Result

The new LP-11 power-on code executed both during probe and during capture:

```text
ov5647_power_on: stream-stop LP-11 setup complete
```

Capture still timed out:

```text
VIDIOC_STREAMON returned 0 (Success)
capture rc=124
raw size=0 bytes path=/home/cam/ov5647_driver_codex/artifacts/captures/20260421T153049Z/ov5647-640x480-bg10.raw
```

Kernel trace still shows repeated VI timeouts:

```text
tegra-camrtc-capture-vi tegra-capture-vi: uncorr_err: request timed out after 2500 ms
```

The stop/power-off cleanup path returned:

```text
ov5647_stop_streaming: exit success
ov5647_power_off: exit success
```

## Logs

- `logs/20260421T152756Z-rmmod-trace.log`
- `logs/20260421T152923Z-manual-insmod-full-delay.log`
- `logs/20260421T153000Z-after-manual-insmod-lp11-state.log`
- `logs/20260421T153001Z-after-manual-insmod-lp11-dmesg.log`
- `logs/20260421T153001Z-after-manual-insmod-lp11-v4l2-query.log`
- `logs/20260421T153001Z-after-manual-insmod-lp11-media-ctl.log`
- `logs/20260421T153049Z-single-frame-trace.log`
- `logs/20260421T153049Z-stream-live-dmesg.log`
- `logs/20260421T153049Z-single-frame-post-dmesg-tail.log`
- `logs/20260421T153224Z-after-lp11-capture-timeout-state.log`
- `logs/20260421T153224Z-after-lp11-capture-timeout-dmesg.log`
- `logs/20260421T153224Z-lp11-capture-timeout-script-log-summary.log`
- `artifacts/captures/20260421T153049Z/ov5647-640x480-bg10.raw`

## Interpretation

LP-11 setup is not sufficient. The failure boundary remains:

- probe succeeds;
- media graph is linked;
- `/dev/video0` exists;
- `VIDIOC_STREAMON` returns success;
- driver start/stop callbacks return;
- VI receives no completed frames.

The next source-side hypothesis is incomplete mode programming. Upstream OV5647 carries per-mode HTS/VTS values and applies them through controls. The local driver still stubs frame-rate/exposure/gain control application, so the minimal mode table should explicitly program the 640x480 HTS/VTS timing before the next runtime capture attempt.

## Next Step

Prepare one source-only patch that adds explicit upstream VGA HTS/VTS register writes to the 640x480 mode table, rebuild, commit, and ask the user to manually run one unload/load/capture cycle.
