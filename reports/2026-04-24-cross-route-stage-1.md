# Cross-Route Stage 1

Date: 2026-04-24

## Goal

Stage one controlled blind cross-route reboot test without changing the driver
baseline or mixing both hybrid routes into the same reboot.

## Rationale

Reference route `A` and reference route `C` both reach:

- chip ID `0x5647`
- `/dev/video0`
- `VIDIOC_STREAMON`

but both still fail with:

- zero-byte raw output
- no `SOF/EOF`
- no `rtcpu_nvcsi_intr`

The remaining narrow DT hypothesis is that the active low-speed path and the
receiver route could be crossed relative to the normal `p3768` assumptions.

## Prepared Overlays

Built artifacts:

- `artifacts/dtbo/20260424T103814Z-ov5647-p3768-cross-i2c0-serialc-probe.dtbo`
- `artifacts/dtbo/20260424T103814Z-ov5647-p3768-cross-i2c1-serialb-probe.dtbo`

Overlay intent:

- stage 1:
  - `cam_i2cmux/i2c@0`
  - `pwdn-gpios = <&gpio 0x3e 0>`
  - `serial_c`
  - `port-index = 2`
- stage 2, not yet staged as default:
  - `cam_i2cmux/i2c@1`
  - `reset-gpios = <&gpio 0xa0 0>`
  - `serial_b`
  - `port-index = 1`

## On-Disk Boot Staging

Boot copies now exist for both hybrids:

- `/boot/ov5647-p3768-cross-i2c0-serialc-probe.dtbo`
- `/boot/ov5647-p3768-cross-i2c1-serialb-probe.dtbo`

The development boot entry is staged to use only:

- `/boot/ov5647-p3768-cross-i2c0-serialc-probe.dtbo`

Safe profile remains overlay-free.

## Important Constraint

This is a blind non-reference experiment.

It does not replace the repository baseline:

- canonical DT baseline remains `patches/ov5647-p3768-port-c-reference.dts`

If this hybrid path also produces `no SOF`, that result should be treated as one
more negative check, not as evidence that the physical 22-pin path is sound.
