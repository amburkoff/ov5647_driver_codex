# 2026-04-21 Route-A Analysis And VGA Table Cleanup

## Summary

After the HTS/VTS capture timeout, a read-only DT/media graph inspection was performed. The active OV5647 route matches NVIDIA's installed p3768 route-A camera overlays for the key routing fields. A single source-side cleanup was then made to align the local 640x480 OV5647 table more closely with upstream/Raspberry Pi VGA mode data.

No risky runtime command was run from Codex.

## Read-Only Findings

Active live route:

- sensor node: `/bus@0/cam_i2cmux/i2c@0/ov5647_a@36`;
- Linux I2C bus: `i2c-9`;
- sensor address: `0x36`;
- CSI interface: `serial_b`;
- endpoint `port-index`: `1`;
- endpoint `bus-width`: `2`;
- mode `lane_polarity`: `"6"`;
- media graph: `nv_ov5647 9-0036 -> nvcsi -> vi-output`.

NVIDIA reference overlays in `/boot` show:

- `imx219-A` and `imx477-A`: `cam_i2cmux/i2c@0`, `serial_b`, `port-index=1`, `bus-width=2`, GPIO token `0x3e`, `lane_polarity=6`;
- `imx219-C` and `imx477-C`: `cam_i2cmux/i2c@1`, `serial_c`, `port-index=2`, GPIO token `0xa0`.

Interpretation: the current overlay is consistent with NVIDIA p3768 route A. I2C/probe success plus NVIDIA route consistency reduce the likelihood of a simple DT route-A modeling error, but they do not prove the physical CLB connector/cable CSI lane path.

## Source Change

Changed file:

- `src/nv_ov5647/nv_ov5647.c`

Change:

- removed local-only VGA register write `0x5002 = 0x41`;
- removed local-only VGA register write `0x4837 = 0x16`;
- kept `0x3821 = 0x01`, because it matches the Raspberry Pi 6.6.y OV5647 VGA table for Pi-style modules;
- kept explicit HTS/VTS writes because the local tegracam control callbacks are still stubs.

Reason:

- both mainline Linux and Raspberry Pi 6.6.y VGA `640x480_10bpp` arrays omit `0x5002` and `0x4837`;
- this is the smallest source-side mode-table cleanup before testing an alternate physical route.

## Build

Build command:

```bash
./scripts/build_module.sh
```

Result:

- build passed;
- artifact: `artifacts/build/20260421T154604Z/nv_ov5647.ko`;
- module `srcversion`: `2F4050CDED69B8A5FF0C49F`.

## Logs And Artifacts

- `logs/20260421T154347Z-readonly-live-camera-state.log`
- `logs/20260421T154347Z-readonly-live-dt-camera-grep.log`
- `logs/20260421T154419Z-readonly-live-dt-route-a-fragments.log`
- `logs/20260421T154419Z-readonly-overlay-route-a-source.log`
- `logs/20260421T154419Z-readonly-boot-overlay-state.log`
- `logs/20260421T154428Z-readonly-nvidia-overlay-route-compare.log`
- `logs/20260421T154446Z-readonly-nvidia-imx219-a-c-route-fragments.log`
- `logs/20260421T154511Z-readonly-upstream-rpi-vga-array.log`
- `logs/20260421T154541Z-readonly-sensor-oe-regs-compare.log`
- `logs/20260421T154604Z-build-module-vga-table-cleanup.log`
- `logs/20260421T154619Z-modinfo-vga-table-cleanup.log`
- `logs/20260421T154619Z-diff-vga-table-cleanup.log`
- `artifacts/dt/20260421T154347Z/live-device-tree.dts`
- `artifacts/dt/20260421T154428Z-nvidia-camera-overlays/`
- `artifacts/build/20260421T154604Z/nv_ov5647.ko`

## Next Manual Runtime Test

Do not run this from Codex. The user should run one command at a time only after this commit is pushed:

```bash
sudo /home/cam/ov5647_driver_codex/scripts/run_manual_rmmod_trace.sh
sudo /home/cam/ov5647_driver_codex/scripts/run_manual_insmod_diag.sh full-delay
sudo /home/cam/ov5647_driver_codex/scripts/run_manual_single_frame_trace.sh
```

If this still returns a zero-byte raw file, the next best experiment is likely an alternate route-C overlay, not more route-A register guessing.
