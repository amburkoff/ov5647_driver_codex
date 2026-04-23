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

## Runtime Result

Post-reboot validation confirmed:

- `boot_profile=ov5647-dev`
- live DT `cil_settletime = 58`
- live DT `lane_polarity = 0`
- live DT `tegra_sinterface = "serial_b"`

Manual runtime test result:

- `sudo /home/cam/ov5647_driver_codex/scripts/run_manual_insmod_diag.sh full-delay-dump-mclk24`
- `sudo /home/cam/ov5647_driver_codex/scripts/run_manual_single_frame_rtcpu_trace.sh`

Observed outcome:

- module loaded successfully
- `VIDIOC_STREAMON` returned success
- raw output stayed `0` bytes
- VI still logged repeated `uncorr_err: request timed out after 2500 ms`
- RTCPU/NVCSI trace still showed no SOF/EOF or receiver interrupt events

Interpretation:

- explicit mid-range `cil_settletime = 58` did not change the failure signature;
- receiver-side auto-calibrate vs explicit mid-range settle timing is therefore no longer a strong differentiator for this setup;
- the dominant hypothesis remains physical CSI pinout/remap/orientation mismatch on the current native 22-pin path.
