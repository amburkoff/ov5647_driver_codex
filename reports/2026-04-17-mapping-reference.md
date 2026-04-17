# 2026-04-17 Camera Mapping Reference Checkpoint

## What Changed

- compared the live DT with the installed NVIDIA `p3768` camera overlays;
- extracted the strongest local reference mapping for camera route `A` and route `C`;
- added a non-applicable OV5647 overlay draft template for the preferred reference route;
- updated mapping and overlay design docs.

## Files Changed

- `docs/01a-cbl-carrier-mapping.md`
- `docs/05-dt-overlay-design.md`
- `patches/ov5647-p3768-port-a-reference.dts.in`

## Commands Run

- live DT inspection:
  - `dtc -I fs -O dts /proc/device-tree | grep ...`
- overlay reference extraction:
  - `dtc -I dtb -O dts /boot/tegra234-p3767-camera-p3768-imx219-A.dtbo | grep ...`
  - `dtc -I dtb -O dts /boot/tegra234-p3767-camera-p3768-imx219-C.dtbo | grep ...`
  - `dtc -I dtb -O dts /boot/tegra234-p3767-camera-p3768-imx477-A.dtbo | grep ...`
  - `dtc -I dtb -O dts /boot/tegra234-p3767-camera-p3768-imx477-C.dtbo | grep ...`
- web research:
  - targeted searches for `CBL Developer Kit` Jetson carrier docs

## Findings

- the live DT still does not expose an active camera sensor node, so the running system itself does not prove the real route;
- the installed NVIDIA p3768 overlays do provide a strong local reference baseline;
- route `A` is the cleanest current candidate:
  - `cam_i2cmux/i2c@0`
  - `serial_b`
  - `port-index = 1`
  - `bus-width = 2`
  - reset GPIO token `0x3e`
  - `lane_polarity = 6` in both `imx219-A` and `imx477-A`
- route `C` remains possible, but its lane-polarity treatment is less uniform in the installed overlays.

## Current Root-Cause Hypotheses

- if the physical camera is plugged into the p3768-style `A` connector path, the first OV5647 DT attempt should most likely target route `A`;
- if the CBL carrier deviates from p3768 routing, the installed NVIDIA overlays will still only be a partial reference and must not be treated as final truth.

## Blocking Unknowns

- physical connector actually used on the CBL carrier;
- cable and adapter orientation between the carrier and OV5647;
- real OV5647 control address;
- reset and PWDN GPIO ownership;
- rail names;
- real lane polarity on the actual path.

## Next Smallest Step

1. Confirm whether the physical path is really route `A`.
2. If yes, convert `patches/ov5647-p3768-port-a-reference.dts.in` into a real `.dts` with verified values.
3. Compile the first non-boot overlay locally.
4. Attempt the first controlled chip-ID probe only after that.
