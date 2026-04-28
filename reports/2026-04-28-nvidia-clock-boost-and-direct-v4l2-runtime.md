# 2026-04-28 NVIDIA Clock-Boost And Direct-V4L2 Runtime

## Goal

Execute the NVIDIA-requested runtime sequence:

1. boost `VI/ISP/NVCSI/EMC` clocks through BPMP debugfs;
2. run a direct `v4l2-ctl` stream test outside the RTCPU trace wrapper.

## Commands Run

```bash
sudo /home/cam/ov5647_driver_codex/scripts/run_manual_bpmp_clock_boost.sh
sudo /home/cam/ov5647_driver_codex/scripts/run_manual_v4l2_direct_stream.sh
```

## Clock Boost Result

Log:

- `logs/20260428T074535Z-manual-bpmp-clock-boost.log`

Observed before/after values:

| Clock | Before | Max | After | Result |
|---|---:|---:|---:|---|
| `vi` | `115200000` | `832000000` | `832000000` | boosted successfully |
| `isp` | `115200000` | `1011200000` | `1011200000` | boosted successfully |
| `nvcsi` | `10045312` | `642900000` | `642900000` | boosted successfully |
| `emc` | `2133000000` | `3199000000` | `2133000000` | lock applied, rate did not increase |

So the NVIDIA-recommended boost clearly did take effect for:

- `vi`
- `isp`
- `nvcsi`

but not for `emc`.

## Direct V4L2 Result

Artifacts:

- `artifacts/captures/20260428T074544Z/pre-v4l2-state.log`
- `logs/20260428T074544Z-manual-v4l2-direct-stream.log`
- `logs/20260428T074544Z-manual-v4l2-direct-stream-live-dmesg.log`
- `logs/20260428T074544Z-manual-v4l2-direct-stream-post-dmesg-tail.log`

The helper detected and used:

- `bypass_mode=0`

Current direct V4L2 format inventory still shows only the repository minimal
mode:

- `BG10`
- `640x480`
- `30 fps`

`v4l2-ctl --list-formats-ext` did **not** advertise a `1920x1080 RG10` mode,
so the direct test was intentionally run on the currently implemented and
advertised mode.

Direct streaming result:

- `VIDIOC_REQBUFS` success
- `VIDIOC_QUERYBUF` success
- `VIDIOC_QBUF` success
- `VIDIOC_STREAMON returned 0 (Success)`
- `capture rc = 124`
- raw output size = `0 bytes`

Kernel logs still show the same repeated timeout:

- `tegra-camrtc-capture-vi: uncorr_err: request timed out after 2500 ms`

## Interpretation

This NVIDIA-directed runtime check is negative in the sense that it does not
change the failure class.

What changed:

- `vi`, `isp`, and `nvcsi` were explicitly boosted to their maximum BPMP rates
- direct V4L2 streaming was tested separately from the RTCPU trace wrapper
- `bypass_mode=0` was explicitly applied

What did not change:

- `VIDIOC_STREAMON` still succeeds
- raw output remains `0 bytes`
- repeated VI timeout remains

## Practical Conclusion

The failure is not explained by:

- low default `vi` clock
- low default `isp` clock
- low default `nvcsi` clock
- use of the RTCPU trace wrapper itself
- omission of `bypass_mode=0`

The direct V4L2 path with NVIDIA-style clock boosting still reproduces the
same no-frame-delivery result as the earlier traced helper.
