# 2026-04-17 OV5647 Draft Overlay Build Checkpoint

## What Changed

- recorded additional user-confirmed hardware facts:
  - both Jetson 22-pin CSI connectors are populated;
  - both camera modules are marked `JT-ZERO-V2.0 YH`;
- aligned the scaffold driver DT defaults with NVIDIA-style supply names:
  - `vana`
  - `vdig`
  - `vif`
- added a compile-ready, still-disabled OV5647 route-A draft overlay with one minimal `mode0`;
- validated that the draft overlay compiles into a `.dtbo` without being applied.

## Files Changed

- `src/nv_ov5647/nv_ov5647.c`
- `docs/01a-cbl-carrier-mapping.md`
- `docs/05-dt-overlay-design.md`
- `patches/ov5647-p3768-port-a-draft.dts`

## Commands Run

- upstream OV5647 reference:
  - `curl -L --fail https://raw.githubusercontent.com/torvalds/linux/master/drivers/media/i2c/ov5647.c | sed -n ...`
- local DT and overlay inspection:
  - `dtc -I fs -O dts /proc/device-tree > artifacts/reference/...-live-device-tree.dts`
  - `dtc -I dtb -O dts /boot/kernel_tegra234-p3768-0000+p3767-0000-nv.dtb > artifacts/reference/...-boot-base.dts`
- rebuild module:
  - `./scripts/build_module.sh`
- compile overlay draft:
  - `dtc -@ -I dts -O dtb -o artifacts/dtbo/...-ov5647-p3768-port-a-draft.dtbo patches/ov5647-p3768-port-a-draft.dts`

## Logs Saved

- `logs/20260417T115700Z-reference-inspection.log`
- `logs/20260417T120106Z-build_module-after-regulator-defaults.log`
- `logs/20260417T120106Z-dtc-ov5647-port-a-draft.log`

## Artifacts Saved

- `artifacts/reference/20260417T115757Z-live-device-tree.dts`
- `artifacts/reference/20260417T115816Z-boot-base.dts`
- `artifacts/dtbo/20260417T120134Z-ov5647-p3768-port-a-draft.dtbo`
- `artifacts/build/20260417T120106Z/`

## Tests Passed

- external module rebuild after DT-default updates;
- local draft overlay compilation to `.dtbo`;
- no boot configuration was modified;
- no overlay was applied live;
- no probe path was enabled.

## Tests Failed

- first draft overlay compile attempt failed due to invalid regulator-label references with hyphens.

## Root-Cause Hypothesis For The Failed Draft

- direct `&label` references to regulator nodes with hyphenated names are not safe in this overlay source as written;
- until the active base-DT symbol map is confirmed, the compile-only draft should keep regulator references in the form already accepted by the local scaffold driver.

## Findings

- route-A remains the strongest current first target on the p3768 reference family:
  - `cam_i2cmux/i2c@0`
  - `serial_b`
  - `port-index = 1`
  - `bus-width = 2`
  - `lane_polarity = 6`
- user-confirmed camera module marking `JT-ZERO-V2.0 YH` increases confidence that the sensors are Raspberry Pi-market OV5647 modules, but does not yet identify the exact Jetson-side cable/adaptor chain;
- the compile-ready route-A overlay draft is still intentionally `status = "disabled"` and must not be treated as carrier-verified.

## Next Smallest Step

1. Confirm whether the first controlled target should be the left or right 22-pin connector and bind that to route `A` or `C`.
2. Inspect the base DT symbol map more deeply if phandle-based supply bindings are required before probe.
3. After that, prepare the first controlled DT enablement on one port only and attempt chip-ID read with `allow_hw_probe=1`.

## Reboot Needed

- No.

## Active Boot Profile

- No `boot_profile=*` token exists in `/proc/cmdline` at this checkpoint.
