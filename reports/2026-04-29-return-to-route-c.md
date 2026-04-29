# 2026-04-29 Return To Route-C

## Goal

Return `ov5647-dev` from the temporary `CAM0` / route-A retest branch back to
the current route-C baseline.

## Why

The previous branch existed only to isolate one physical-variable check:

- another OV5647 unit installed on `CAM0`

That route-A retest remained negative, so the temporary `CAM0` branch is no
longer the preferred default debug path.

## Change

`ov5647-dev` was restaged from:

- `/boot/ov5647-p3768-port-a-lanepol0.dtbo`

back to:

- `/boot/ov5647-p3768-port-c-reference-mclk24-pixclk56.dtbo`

The safe profile remains unchanged.

## Artifacts

- `artifacts/boot/20260429T095232Z/extlinux.conf.current`
- `artifacts/boot/20260429T095232Z/extlinux.conf.generated`
- `logs/20260429T095232Z-switch_boot_profile.log`

## Intended Next State After Reboot

- `boot_profile=ov5647-dev`
- live route should return to:
  - `cam_i2cmux/i2c@1/ov5647_c@36`
  - `serial_c`
  - `port-index = 2`
  - `pix_clk_hz = 56004480`

## Next Step

Reboot, verify the live DT route switched back to route C, then continue from
the route-C baseline.
