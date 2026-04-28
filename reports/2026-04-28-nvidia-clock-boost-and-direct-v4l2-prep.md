# 2026-04-28 NVIDIA Clock-Boost And Direct-V4L2 Prep

## Goal

Prepare a safe manual workflow for the next NVIDIA-recommended runtime check:

1. boost `VI/ISP/NVCSI/EMC` clocks through BPMP debugfs;
2. run a direct `v4l2-ctl` stream test, separate from the RTCPU trace wrapper.

## What Changed

Added manual-only helper:

- `scripts/run_manual_bpmp_clock_boost.sh`

This helper:

- sets `mrq_rate_locked=1` for:
  - `vi`
  - `isp`
  - `nvcsi`
  - `emc`
- writes each clock `rate=max_rate`
- logs before/after values to:
  - `logs/<timestamp>-manual-bpmp-clock-boost.log`

Added manual-only helper:

- `scripts/run_manual_v4l2_direct_stream.sh`

This helper:

- saves `v4l2-ctl --list-devices`
- saves `--list-formats-ext`
- saves `--list-ctrls`
- saves `--all`
- then runs direct streaming with defaults:
  - `/dev/video0`
  - `640x480`
  - `BG10`
  - `sensor_mode=0`
  - `stream_count=100`
- if the driver exposes `bypass_mode`, it also sets:
  - `bypass_mode=0`

Artifacts saved by the direct V4L2 helper:

- `artifacts/captures/<timestamp>/pre-v4l2-state.log`
- `logs/<timestamp>-manual-v4l2-direct-stream.log`
- `logs/<timestamp>-manual-v4l2-direct-stream-live-dmesg.log`
- `logs/<timestamp>-manual-v4l2-direct-stream-post-dmesg-tail.log`

## Why This Branch Exists

NVIDIA asked for two things:

- boost all `VI/CSI/ISP` clocks;
- verify camera functionality through direct V4L2 IOCTL usage.

The repository already uses direct `v4l2-ctl` under the trace wrappers, but the
new helper separates that path from RTCPU tracing and keeps the exact runtime
test closer to the requested NVIDIA workflow.

## Current Assumption

The current repository minimal mode is still:

- `BG10`
- `640x480`
- `sensor_mode=0`

so the direct V4L2 helper defaults to that mode rather than switching to an
untested `1920x1080 RG10` path.

## Next Step

Ask the user to run manually, in order:

```bash
sudo /home/cam/ov5647_driver_codex/scripts/run_manual_bpmp_clock_boost.sh
sudo /home/cam/ov5647_driver_codex/scripts/run_manual_v4l2_direct_stream.sh
```

Then inspect whether:

- `--list-formats-ext` still advertises only the minimal `BG10 640x480` mode;
- the boosted clocks change the failure signature at all;
- direct `v4l2-ctl` behaves any differently from the traced single-frame helper.
