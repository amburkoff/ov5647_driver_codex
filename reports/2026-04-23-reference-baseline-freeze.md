# Reference Baseline Freeze

Date: 2026-04-23

## Goal

Freeze one repository baseline that represents the current software-most-correct
OV5647 configuration for further comparisons, instead of continuing to compare
against multiple experimental route-A and route-C branches.

## Chosen Reference Baseline

The repository reference DT branch is now:

- route `C`
- `cam_i2cmux/i2c@1`
- sensor node `ov5647_c@36`
- `tegra_sinterface = "serial_c"`
- `port-index = <2>`
- `bus-width = <2>`
- `lane_polarity = "0"`
- `reset-gpios = <&gpio 0xa0 0>`
- no `pwdn-gpios`
- `mclk = "extperiph1"`
- `mclk_khz = "25000"`
- `discontinuous_clk = "yes"`
- `cil_settletime = "0"`

This choice is based on the reviewed external Orin NX route-C example and on the
fact that it is the cleanest current branch with:

- explicit `reset-gpios`
- no ambiguous `pwdn-gpios`
- a single minimal mode
- two-lane configuration only

## Important Constraint

This is a reference baseline, not a declared working electrical configuration.

Current evidence still shows:

- probe succeeds
- chip ID is correct
- `/dev/video0` appears after manual module load
- `VIDIOC_STREAMON` succeeds
- capture still returns `0 bytes`
- VI still times out with repeated `uncorr_err`
- RTCPU/NVCSI still show no SOF/frame ingress

## Driver Baseline

The driver source remains aligned with the current narrow bring-up target:

- one sensor
- one minimal mode
- explicit LP-11 setup
- output-enable handling
- detailed probe/power/stream logging
- diagnostics retained as opt-in module parameters only

The latest explicit MCLK override result is also frozen:

- `clk_set_rate(25000000)` is reached
- the effective `extperiph1` rate still remains `24000000`

## Repo Effect

The canonical DT source for this baseline is:

- `patches/ov5647-p3768-port-c-reference.dts`

The development boot profile is staged to use the matching `/boot` overlay for
future reboot-based comparisons, while the safe profile remains unchanged.
