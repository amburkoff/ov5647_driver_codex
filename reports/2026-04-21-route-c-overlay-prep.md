# 2026-04-21 Route-C Overlay Prep

## Summary

An alternate OV5647 route-C probe overlay was prepared after repeated route-A capture timeouts. The overlay is buildable and matches NVIDIA p3768 route-C conventions for the second 22-pin camera route.

The live `/boot` configuration was not modified in this checkpoint.

## Route-C Candidate

New source:

- `patches/ov5647-p3768-port-c-probe.dts`

Key route fields:

- sensor node: `/bus@0/cam_i2cmux/i2c@1/ov5647_c@36`;
- I2C mux leg: `cam_i2cmux/i2c@1`;
- sensor address: `0x36`;
- CSI interface: `serial_c`;
- endpoint `port-index`: `2`;
- endpoint `bus-width`: `2`;
- route-C PWDN candidate: GPIO token `0xa0`;
- lane polarity candidate: `"0"`.

Reference basis:

- NVIDIA `imx219-C` uses `cam_i2cmux/i2c@1`, `serial_c`, `port-index=2`, GPIO token `0xa0`;
- NVIDIA `imx477-C` uses the same route and explicitly sets `lane_polarity = "0"`;
- NVIDIA `imx219-C` omits explicit lane polarity, treated here as default `0`.

## Build

Command:

```bash
./scripts/build_overlay.sh patches/ov5647-p3768-port-c-probe.dts
```

Result:

- built DTBO: `artifacts/dtbo/20260421T155351Z-ov5647-p3768-port-c-probe.dtbo`;
- decompiled DTBO confirms `serial_c`, `port-index=2`, `i2c@1`, `ov5647_c@36`, and `pwdn-gpios = <... 0xa0 ...>`.

Remaining warnings:

- standard overlay unit-address warnings for fragment target nodes;
- `graph_port` warning for `tegra-capture-vi/ports/port@1` with `reg=<0>`.

The `graph_port` warning is accepted for now because the installed NVIDIA `imx219-C` overlay uses the same `port@1` / `reg=<0>` structure.

## Boot Render Check

Rendered candidate only:

```bash
./scripts/switch_boot_profile.sh --render-only --default dev --dev-overlay /boot/ov5647-p3768-port-c-probe.dtbo
```

Rendered config:

- `artifacts/boot/20260421T155412Z/extlinux.conf.generated`

Rendered state:

- default would be `ov5647-dev`;
- safe profile remains present;
- dev profile would use `OVERLAYS /boot/ov5647-p3768-port-c-probe.dtbo`.

## Next Step

After this checkpoint is committed and pushed, the next controlled action is to stage the route-C DTBO into `/boot`, apply the rendered dev boot profile, and ask the user to run exactly:

```bash
sudo reboot
```

Codex must not run the reboot command.
