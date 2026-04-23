# CIL Settletime 58 Stage

Date: 2026-04-23

## Why This Experiment

The `PWDN/CAM_IO0` diagnostic matrix narrowed the software-only hypotheses:

- `pwdn=normal` -> probe ok, no SOF
- `pwdn=ignore` -> probe ok, no SOF
- `pwdn=ignore + keep-powered` -> probe ok, no SOF
- `pwdn=inverted` -> early I2C/register access fails, so active-low is not the right polarity for the current control line

This makes the next strongest software-only hypothesis a receiver-side timing issue, specifically `cil_settletime`.

## Source Of Truth

NVIDIA Jetson Linux r36.x documents:

- `cil_settletime = 0` means auto-calibrate
- for DPHY, the acceptable settle window is:
  - `85 ns + 6*UI < cil_settletime * lp_clock_period < 145 ns + 10*UI`
  - `lp_clock_period = 1 / 408 MHz`

Reference:

- NVIDIA Jetson Linux Developer Guide, Sensor Software Driver Programming

## Local Inference For This OV5647 Mode

For the current minimal mode:

- `pix_clk_hz = 58,333,000`
- `csi_pixel_bit_depth = 10`
- `num_lanes = 2`

Approximate lane bit rate inference:

- `lane_rate ~= pix_clk_hz * bits_per_pixel / num_lanes`
- `lane_rate ~= 58.333 MHz * 10 / 2 ~= 291.665 Mbps`
- `UI ~= 1 / lane_rate ~= 3.43 ns`

This gives an approximate acceptable THS-settle range:

- low ~= `105.6 ns`
- high ~= `179.3 ns`
- midpoint ~= `142.4 ns`

Converting midpoint into Jetson's `cil_settletime` units:

- `lp_clock_period ~= 2.451 ns`
- `142.4 / 2.451 ~= 58.1`

Chosen controlled experiment:

- `cil_settletime = "58"`

## Files Added

- `patches/ov5647-p3768-port-a-lanepol0-cil58-probe.dts`

## Success Criterion

- any change from the current `VIDIOC_STREAMON ok + no SOF + 0 bytes` pattern
- ideally real frame ingress, or at least new NVCSI/VI events

## Failure Interpretation

If explicit mid-range `cil_settletime = 58` still produces no SOF, the remaining software-only room narrows further and the physical pinout/remap hypothesis becomes even stronger.
