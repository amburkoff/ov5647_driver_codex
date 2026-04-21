# DT Overlay Design

Design intent:

- start from the current `p3768` reference camera overlay structure shipped with Jetson Linux `r36.5`;
- replace sensor-specific pieces with OV5647 data only after the physical connector, CSI path, and power wiring are verified;
- keep the first overlay minimal and single-sensor.

## Current Ground Truth

- the live dev boot has an active OV5647 route-A overlay;
- `cam_i2c` resolves to `i2c@3180000`;
- NVIDIA p3768 reference overlays on disk describe 22-pin camera routes through `cam_i2cmux`;
- reference route `A` maps to `serial_b` and `port-index = 1`;
- reference route `C` maps to `serial_c` and `port-index = 2`.
- the active live route is:
  - `cam_i2cmux/i2c@0/ov5647_a@36`;
  - Linux downstream bus `i2c-9`;
  - `serial_b`;
  - `port-index = 1`;
  - `bus-width = 2`;
  - `lane_polarity = "6"`.

## Minimal OV5647 Overlay Plan

The first OV5647 overlay will need:

- one `tegra-capture-vi` port;
- one `nvcsi` channel;
- one `tegra-camera-platform` module entry;
- one sensor node on the verified camera I2C path;
- one `mode0` only;
- no experimental boot-time enablement until manual probe is stable.

Current active reference target:

- p3768-style route `A`
- `cam_i2cmux/i2c@0`
- `serial_b`
- `port-index = 1`
- `bus-width = 2`
- reference `lane_polarity = 6`

Reason:

- both installed NVIDIA `imx219-A` and `imx477-A` overlays agree on this mapping;
- the active OV5647 route-A overlay matches those NVIDIA route fields;
- OV5647 chip ID is confirmed at `i2c-9` / `0x36`;
- the route `C` references are less uniform for lane-polarity handling.

Fields that remain blocked until hardware verification:

- physical connector selection for the first single-sensor milestone
- whether the path exposes only `pwdn-gpios` or separate `reset-gpios` and `pwdn-gpios`
- exact clock wiring beyond the default `extperiph1` assumption
- final rail mapping on the real carrier path
- whether the CBL physical connector/cable path actually matches NVIDIA route A electrically

## Safe Boot Interaction

- the generated `ov5647-safe` profile will not reference any OV5647 overlay;
- the generated `ov5647-dev` profile currently uses `OVERLAYS /boot/ov5647-p3768-port-a-probe.dtbo`;
- `FDTOVERLAYS` did not apply correctly on this UEFI boot path; the working syntax is `FDT` plus `OVERLAYS`.

## Draft Overlay Artifact

The repository now contains:

- `patches/ov5647-p3768-port-a-reference.dts.in`
- `patches/ov5647-p3768-port-a-draft.dts`
- `patches/ov5647-p3768-port-a-probe.dts`

- `ov5647-p3768-port-a-reference.dts.in` remains the unconstrained placeholder template.
- `ov5647-p3768-port-a-draft.dts` is a compile-ready draft for local build validation only.
- `ov5647-p3768-port-a-probe.dts` is the active route-A candidate currently used by the dev profile.
- The draft keeps the sensor node `status = "disabled"` and must not be treated as a verified or boot-ready carrier overlay.
