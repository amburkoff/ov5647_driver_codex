# Return To Reference Baseline

Date: 2026-04-24

## Goal

Return the staged `ov5647-dev` boot entry from the blind cross-route hybrids to
the canonical route-C reference overlay after both hybrid runtime checks proved
negative.

## Why

Both blind hybrids:

- `i2c@0 + serial_c + port-index=2`
- `i2c@1 + serial_b + port-index=1`

produced the same runtime signature as the earlier reference routes:

- `VIDIOC_STREAMON` success
- zero-byte raw capture
- `receiver_signature=no_receiver_ingress_visible`
- `clk_pm_signature=vi_and_nvcsi_clocks_observed_during_timeout`

That closes the software-only route-permutation branch with no improvement.

## On-Disk Boot State

`ov5647-dev` is now staged back to:

- `/boot/ov5647-p3768-port-c-reference.dtbo`

Safe profile remains overlay-free.

`extlinux.conf` now renders:

- `DEFAULT ov5647-dev`
- `OVERLAYS /boot/ov5647-p3768-port-c-reference.dtbo`

## Effect

Future reboot-based comparisons can again start from the canonical route-C
baseline instead of a blind hybrid branch.
