# 2026-04-28 CAM0 New Unit Route-A Runtime

## Goal

Retest the route-A / `CAM0` path after physically replacing the OV5647 module
 in `CAM0` with another unit, while keeping the logical route and runtime
 procedure unchanged.

## Route Confirmation

After reboot, live DT correctly switched back to the intended `CAM0` route:

- `cam_i2cmux/i2c@0/ov5647_a@36`
- `serial_b`
- `port-index = 1`
- `num_lanes = 2`
- `lane_polarity = 0`
- `mclk_khz = 24000`

So this runtime really exercised the newly swapped camera in `CAM0`, not the
previous route-C path.

## Commands Run

```bash
sudo /home/cam/ov5647_driver_codex/scripts/run_manual_insmod_diag.sh full-delay-dump
sudo /home/cam/ov5647_driver_codex/scripts/run_manual_bpmp_clock_boost.sh
sudo /home/cam/ov5647_driver_codex/scripts/run_manual_v4l2_direct_stream.sh
```

## Artifacts

- `artifacts/captures/20260428T142755Z/pre-v4l2-state.log`
- `artifacts/captures/20260428T142755Z/ov5647-640x480-bg10-count100.raw`
- `logs/20260428T142746Z-manual-bpmp-clock-boost.log`
- `logs/20260428T142755Z-manual-v4l2-direct-stream.log`
- `logs/20260428T142755Z-manual-v4l2-direct-stream-live-dmesg.log`
- `logs/20260428T142755Z-manual-v4l2-direct-stream-post-dmesg-tail.log`

## Result

Manual `insmod` succeeded:

- module `srcversion = ADC5D388AC61C3B9AA9276E`
- `insmod rc = 0`

BPMP clock boost again confirmed:

- `vi = 832000000`
- `isp = 1011200000`
- `nvcsi = 642900000`
- `emc` again stayed at `2133000000` even though `max_rate = 3199000000`

Direct V4L2 streaming again produced the same outcome:

- `VIDIOC_STREAMON returned 0 (Success)`
- `capture rc = 124`
- raw output size `0 bytes`
- repeated:
  - `tegra-camrtc-capture-vi: uncorr_err: request timed out after 2500 ms`

## Additional Notes

Current direct V4L2 inventory on route A still shows only:

- `BG10`
- `640x480`
- `30 fps`

and `bypass_mode=0` was applied again.

The driver again showed the same stream-register lifecycle:

- stream-on succeeds;
- sensor-side registers remain in streaming state until explicit stop;
- then return to standby/LP11 only after stream-off.

## Conclusion

This negative retest weakens the "single bad OV5647 camera unit" hypothesis.

Compared with the previous route-A direct-V4L2 result, the hardware variable
changed:

- different physical OV5647 module installed in `CAM0`

But the failure class did not change:

- `VIDIOC_STREAMON` success
- zero-byte raw output
- repeated VI timeout

So replacing only the physical camera unit in `CAM0` did not resolve the
missing-frame problem on the route-A path.
