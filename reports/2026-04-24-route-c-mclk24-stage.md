# Route-C MCLK24 Stage

Date: 2026-04-24

## Goal

Prepare one controlled reboot-only retest that closes the remaining DT-intent
vs runtime clock gap on the canonical route-C baseline.

## Change Scope

New overlay:

- `patches/ov5647-p3768-port-c-reference-mclk24.dts`

Built artifact:

- `artifacts/dtbo/20260424T131500Z-ov5647-p3768-port-c-reference-mclk24.dtbo`

Installed boot copy:

- `/boot/ov5647-p3768-port-c-reference-mclk24.dtbo`

Boot staging:

- `ov5647-dev`
- `OVERLAYS /boot/ov5647-p3768-port-c-reference-mclk24.dtbo`

## Controlled Variable

This retest keeps the canonical route-C baseline unchanged except for the MCLK
intent tuple:

- `mclk_khz: 25000 -> 24000`
- `mclk_multiplier: 2.33 -> 2.43`

Unchanged:

- `cam_i2cmux/i2c@1`
- `serial_c`
- `port-index = 2`
- `lane_polarity = 0`
- `num_lanes = 2`
- `reset-gpios = <&gpio 0xa0 0>`
- `discontinuous_clk = yes`
- `cil_settletime = 0`

## Why This Test Exists

The focused audit established:

- official NVIDIA route-C overlays on this platform family use `mclk_khz=24000`
- current canonical OV5647 route-C overlay used `25000`
- runtime still enabled `24000000` anyway

This retest removes that remaining mismatch cleanly, without changing route or
media-graph structure.
