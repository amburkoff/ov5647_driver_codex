# DT Overlay Design

Design intent:

- start from the current `p3768` reference camera overlay structure shipped with Jetson Linux `r36.5`;
- replace sensor-specific pieces with OV5647 data only after the physical connector, CSI path, and power wiring are verified;
- keep the first overlay minimal and single-sensor.

## Current Ground Truth

- the live dev boot has an active OV5647 route-A corrected-MCLK overlay;
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
  - `lane_polarity = "6"`;
  - `discontinuous_clk = "yes"`.

## Minimal OV5647 Overlay Plan

The first OV5647 overlay will need:

- one `tegra-capture-vi` port;
- one `nvcsi` channel;
- one `tegra-camera-platform` module entry;
- one sensor node on the verified camera I2C path;
- one `mode0` only;
- no experimental boot-time enablement until manual probe is stable.

Current active runtime target:

- p3768-style route `A`
- `cam_i2cmux/i2c@0`
- `serial_b`
- `port-index = 1`
- `bus-width = 2`
- reference `lane_polarity = 6`
- receiver-side discontinuous clock: `discontinuous_clk = "yes"`

Reason:

- route `A` produced valid probe/chip ID but repeated zero-byte capture timeouts;
- route `C` also produced valid probe/chip ID and `/dev/video0`, but capture still timed out;
- the current route-A overlay is the latest boot-applied experiment and matches the physical `cam0` test requested by the user.

Fields that remain blocked until hardware verification:

- physical connector selection for the first single-sensor milestone
- whether the path exposes only `pwdn-gpios` or separate `reset-gpios` and `pwdn-gpios`
- exact clock wiring beyond the default `extperiph1` assumption
- final rail mapping on the real carrier path
- whether the CLB physical connector/cable path actually matches NVIDIA p3768 route A or route C electrically
- whether the `JT-ZERO-V2.0 YH` Raspberry Pi-style camera flex/module path is pin-compatible with the Jetson/CLB 22-pin connector orientation

## Safe Boot Interaction

- the generated `ov5647-safe` profile will not reference any OV5647 overlay;
- the generated `ov5647-dev` profile is staged for the next reboot with `OVERLAYS /boot/ov5647-p3768-port-a-extperiph1.dtbo`;
- the currently running live DT remains whatever was loaded at boot until the next reboot;
- `FDTOVERLAYS` did not apply correctly on this UEFI boot path; the working syntax is `FDT` plus `OVERLAYS`.

## Draft Overlay Artifact

The repository now contains:

- `patches/ov5647-p3768-port-a-reference.dts.in`
- `patches/ov5647-p3768-port-a-draft.dts`
- `patches/ov5647-p3768-port-a-probe.dts`
- `patches/ov5647-p3768-port-a-lanepol0-probe.dts`
- `patches/ov5647-p3768-port-c-probe.dts`

- `ov5647-p3768-port-a-reference.dts.in` remains the unconstrained placeholder template.
- `ov5647-p3768-port-a-draft.dts` is a compile-ready draft for local build validation only.
- `ov5647-p3768-port-a-probe.dts` is the first route-A candidate; it probe-validated but capture timed out.
- `ov5647-p3768-port-a-lanepol0-probe.dts` differs from the route-A probe only by `lane_polarity = "0"` and traceable names/badges.
- `ov5647-p3768-port-c-probe.dts` is the route-C candidate; it probe-validated but capture timed out.
- The draft keeps the sensor node `status = "disabled"` and must not be treated as a verified or boot-ready carrier overlay.

## Route-C Candidate

Route-C candidate fields:

- `cam_i2cmux/i2c@1`;
- `ov5647_c@36`;
- `tegra_sinterface = "serial_c"`;
- endpoint `port-index = <2>`;
- endpoint `bus-width = <2>`;
- `pwdn-gpios = <&gpio 0xa0 0>`;
- `lane_polarity = "0"`.

Reference basis:

- NVIDIA `imx219-C` and `imx477-C` both use `i2c@1`, `serial_c`, `port-index=2`, and GPIO token `0xa0`;
- NVIDIA `imx477-C` explicitly uses `lane_polarity = "0"`;
- NVIDIA `imx219-C` omits explicit lane polarity, so default `0` is the least surprising route-C candidate.

Status:

- `artifacts/dtbo/20260421T155351Z-ov5647-p3768-port-c-probe.dtbo` builds;
- `artifacts/boot/20260421T155412Z/extlinux.conf.generated` renders a dev profile using `/boot/ov5647-p3768-port-c-probe.dtbo`;
- `artifacts/dtbo/20260422T082931Z-ov5647-p3768-port-c-probe.dtbo` builds with `discontinuous_clk = "no"`;
- the live `/boot` dev profile now uses `/boot/ov5647-p3768-port-c-extperiph1.dtbo`;
- live DT confirms route-C fields after reboot;
- route-C corrected-`extperiph1` continuous-clock capture still times out with zero-byte output;
- RTCPU/NVCSI trace shows no SOF or NVCSI receiver interrupt during the capture window.

## Route-A Corrected-MCLK Retest

The route-A overlay has been rebuilt after the Tegra234 BPMP clock-ID fix:

- source: `patches/ov5647-p3768-port-a-probe.dts`;
- artifact: `artifacts/dtbo/20260422T135929Z-ov5647-p3768-port-a-probe.dtbo`;
- boot copy: `/boot/ov5647-p3768-port-a-extperiph1.dtbo`;
- route: `cam_i2cmux/i2c@0`, `serial_b`, `port-index=1`, `lane_polarity="6"`;
- clock: `clocks = <&bpmp 0x24>`, `clock-names = "extperiph1"`;
- dev profile default is staged for this overlay, but live DT validation still requires reboot.

Post-reboot validation:

- active boot profile is `boot_profile=ov5647-dev`;
- live DT contains `bus@0/cam_i2cmux/i2c@0/ov5647_a@36`;
- live DT does not contain the route-C `ov5647_c@36` node;
- live route-A clock binding is `clocks_hex = 00 00 00 03 00 00 00 24`;
- media graph has no sensor entity until the manual module load, which is expected because the driver is not auto-loaded.

## Current DT Conclusion

The DT overlay is good enough to bind the sensor, register `/dev/video0`, and execute stream start on route C. It is not proven electrically correct because neither route A nor route C produces SOF.

The next DT work should be tightly bounded:

- route A with `lane_polarity = "6"` has failed with corrected MCLK, `0x3821 = 0x03`, continuous sensor clock, and matched non-continuous sensor clock;
- the next staged DT candidate is a one-variable route-A lane-polarity check: `lane_polarity = "0"`;
- after that, prefer hardware evidence over more blind edits: confirmed CLB connector label to p3768 route mapping, makerobo CLB camera connector wiring, cable/adapter pinout for the Raspberry Pi Zero-style OV5647 modules, or a known-good Jetson camera cross-check.

## Route-A Lane-Polarity-0 Stage

The next reboot-only candidate is now staged:

- source: `patches/ov5647-p3768-port-a-lanepol0-probe.dts`;
- artifact: `artifacts/dtbo/20260423T080742Z-ov5647-p3768-port-a-lanepol0-probe.dtbo`;
- boot copy: `/boot/ov5647-p3768-port-a-lanepol0.dtbo`;
- dev profile overlay: `OVERLAYS /boot/ov5647-p3768-port-a-lanepol0.dtbo`;
- boot default remains `ov5647-dev`;
- safe profile remains present and unchanged.

This stage intentionally changes only one DT variable relative to the current route-A test line:

- `lane_polarity = "0"` instead of `lane_polarity = "6"`.
