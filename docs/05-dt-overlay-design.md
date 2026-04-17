# DT Overlay Design

Design intent:

- start from the current `p3768` reference camera overlay structure shipped with Jetson Linux `r36.5`;
- replace sensor-specific pieces with OV5647 data only after the physical connector, CSI path, and power wiring are verified;
- keep the first overlay minimal and single-sensor.

## Current Ground Truth

- the live system has no active camera sensor overlay;
- `cam_i2c` resolves to `i2c@3180000`;
- NVIDIA p3768 reference overlays on disk describe 22-pin camera routes through `cam_i2cmux`;
- reference route `A` maps to `serial_b` and `port-index = 1`;
- reference route `C` maps to `serial_c` and `port-index = 2`.

## Minimal OV5647 Overlay Plan

The first OV5647 overlay will need:

- one `tegra-capture-vi` port;
- one `nvcsi` channel;
- one `tegra-camera-platform` module entry;
- one sensor node on the verified camera I2C path;
- one `mode0` only;
- no experimental boot-time enablement until manual probe is stable.

Current preferred reference target, pending physical verification:

- p3768-style route `A`
- `cam_i2cmux/i2c@0`
- `serial_b`
- `port-index = 1`
- `bus-width = 2`
- reference `lane_polarity = 6`

Reason:

- both installed NVIDIA `imx219-A` and `imx477-A` overlays agree on this mapping;
- the route `C` references are less uniform for lane-polarity handling.

Fields that remain blocked until hardware verification:

- `reg`
- `reset-gpios`
- `pwdn-gpios`
- `clocks` and exact MCLK name
- supply names
- `tegra_sinterface`
- `port-index`
- `lane_polarity`

## Safe Boot Interaction

- the generated `ov5647-safe` profile will not reference any OV5647 overlay;
- the generated `ov5647-dev` profile currently adds only a `boot_profile=ov5647-dev` marker;
- adding `FDTOVERLAYS` for OV5647 is deferred until the manual overlay path is validated.

## Draft Overlay Artifact

The repository now contains a non-applicable template:

- `patches/ov5647-p3768-port-a-reference.dts.in`

It is intentionally a `.dts.in` template, not a compiled or boot-ready overlay. It captures the currently preferred route and the fields that still require verified hardware values before conversion into a real `.dtbo`.

