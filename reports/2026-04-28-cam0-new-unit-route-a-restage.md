# 2026-04-28 CAM0 New Unit Route-A Restage

## Goal

Retest the hardware variable "different OV5647 unit installed on CAM0" without
mixing in another logical route change.

## Why Restaging Was Needed

After the physical camera swap on `CAM0`, the system was still booted into the
current `ov5647-dev` route-C overlay:

- `cam_i2cmux/i2c@1/ov5647_c@36`
- `serial_c`
- `port-index = 2`
- `pix_clk_hz = 56004480`

So the freshly swapped `CAM0` module was not being exercised at all on that
boot.

Read-only confirmation artifact:

- `artifacts/camera-route-state/20260428T142148Z/live-dt-ov5647-route-summary.log`

## Controlled Choice

For the next reboot, `ov5647-dev` is restaged to the already-known route-A
lane-polarity-0 overlay:

- `/boot/ov5647-p3768-port-a-lanepol0.dtbo`

This keeps the logical camera route aligned with `CAM0` and avoids mixing in a
new DT/timing experiment at the same time as the physical camera-unit swap.

## What This Isolates

Compared with the last route-A lane-polarity-0 runtime history, the intended
next reboot changes only the physical camera unit in `CAM0`.

The route assumptions remain:

- `cam_i2cmux/i2c@0`
- `serial_b`
- `port-index = 1`
- `bus-width = 2`
- `lane_polarity = 0`
- `mclk_khz = 24000`

## Next Step

Reboot into the restaged `ov5647-dev` profile, verify live DT has moved back to
route A, then rerun the usual manual:

- `insmod`
- BPMP clock boost
- direct V4L2 stream test

If the failure signature changes, the swapped camera unit is relevant. If the
failure signature stays identical, that further weakens the "single bad camera
unit" hypothesis.
