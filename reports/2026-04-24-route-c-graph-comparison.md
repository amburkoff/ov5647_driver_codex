# Route-C Graph Comparison

Date: 2026-04-24

## Goal

Compare the canonical OV5647 route-C graph against official NVIDIA route-C
camera overlays on the same `p3768` family target, to see whether the current
failure could still be explained by an obvious graph-shape mismatch.

## Inputs

Live runtime inputs:

- `artifacts/reference-baseline-state/20260424T124209Z`
- traced runtime after restore:
  - `artifacts/traces/20260424T130137Z`

Reference overlays:

- `/boot/tegra234-p3767-camera-p3768-imx219-C.dtbo`
- `/boot/tegra234-p3767-camera-p3768-imx477-C.dtbo`

Helper:

- `scripts/compare_route_c_graphs.sh`
- output:
  - `artifacts/graph-compare/20260424T130645Z/graph-summary.txt`

## Live Media Graph

With `nv_ov5647` loaded on the canonical route-C baseline, the live media graph
is:

- `nv_ov5647 9-0036 -> 13e00000.host1x:nvcsi@15a00000- -> vi-output, nv_ov5647 9-0036`

All links are enabled and `/dev/video0`, `/dev/v4l-subdev0`, and
`/dev/v4l-subdev1` are present.

## Structural Comparison

Canonical OV5647 route-C matches the official NVIDIA route-C overlays on the
main structural axes:

- `module1`
- `cam_i2cmux/i2c@1`
- `tegra_sinterface = "serial_c"`
- `port-index = 2`
- `num_lanes = 2`
- `reset-gpios` present

Useful NVIDIA reference nuance:

- `imx219-C` uses:
  - `tegra-capture-vi/port@1`
  - `nvcsi/channel@1`
- `imx477-C` uses:
  - `tegra-capture-vi/port@0`
  - `nvcsi/channel@0`

So NVIDIA's own route-C overlays already show that internal graph numbering is
not unique for the same external route.

That means the OV5647 route-C choice:

- `tegra-capture-vi/port@1`
- `nvcsi/channel@1`

is still within observed NVIDIA route-C patterns and is not, by itself, an
obvious bug.

## Remaining Differences

The remaining differences versus official references are sensor-specific, not
route-shape-specific:

- no lens drivernode
- no embedded metadata
- different mode geometry and timing
- DT `mclk_khz = 25000` intent while runtime still enables `24000000`
- `discontinuous_clk = yes` like `imx219-C`, not `no` like `imx477-C`

## Conclusion

This comparison lowers the priority of the hypothesis that the canonical
route-C failure is caused by a simple DT/media-graph topology mistake.

It does not prove the route is electrically correct, but it does show that the
current OV5647 route-C graph is structurally close to official NVIDIA route-C
patterns while still producing:

- `receiver_signature=no_receiver_ingress_visible`
- zero-byte raw captures
- repeated VI timeouts
