# 2026-04-27 Route-C `pix_clk_hz=56004480` Stage

## Goal

Follow NVIDIA support guidance to review Sensor Pixel Clock on the canonical
OV5647 route-C baseline and stage one controlled reboot-only retest that
changes only `pix_clk_hz` and the directly dependent mode timing fields.

Forum context:

- https://forums.developer.nvidia.com/t/ov5647-jt-zero-v2-0-raspberri-pi-zerro-22pin-like-camera-with-jetson-orin-nx-csi-data-is-not-coming-in/368011/4

Official NVIDIA references reviewed for this step:

- https://docs.nvidia.com/jetson/archives/r36.5/DeveloperGuide/SD/CameraDevelopment/SensorSoftwareDriverProgramming.html#sensor-pixel-clock
- https://docs.nvidia.com/jetson/archives/r36.5/DeveloperGuide/SD/CameraDevelopment/SensorSoftwareDriverProgramming.html#to-verify-that-mode-specific-settings-are-correct

## Why This Retest Exists

The canonical route-C baseline was already aligned with the main NVIDIA
capture-side route fields:

- `serial_c`
- `port-index = 2`
- `bus-width = 2`
- `num_lanes = 2`
- `mclk_khz = 24000`
- `lane_polarity = 0`
- `cil_settletime = 0`

The one remaining software-side field with meaningful weight was
`pix_clk_hz`.

Live DT still advertised:

- `pix_clk_hz = 58333000`

But the latest runtime OV5647 register dumps for the active VGA mode showed:

- `HTS = 0x073c = 1852`
- `VTS = 0x01f8 = 504`
- target `fps = 60`

That implies:

- `1852 * 504 * 60 = 56004480`

So the DT pixel clock intent was not self-consistent with the sensor timing
that the driver actually programmed.

## Live DT Evidence

Saved by:

- `sudo dtc -I fs -O dts /sys/firmware/devicetree/base > ...`

Artifacts:

- `artifacts/dt-live/20260427T091301Z/live-device-tree.dts`
- `logs/20260427T091301Z-dump-live-dt-fs.log`

Relevant live DT values before this stage:

- `mclk_khz = "24000"`
- `pix_clk_hz = "58333000"`
- `line_length = "1852"`
- `default_framerate = "60000000"`
- `embedded_metadata_height = "0"`

## Controlled DT Change

New overlay source:

- `patches/ov5647-p3768-port-c-reference-mclk24-pixclk56.dts`

Built DTBO:

- `artifacts/dtbo/20260427T091419Z-ov5647-p3768-port-c-reference-mclk24-pixclk56.dtbo`

Installed boot DTBO:

- `/boot/ov5647-p3768-port-c-reference-mclk24-pixclk56.dtbo`

### Fields Changed

Only the route-C baseline pixel-clock intent and directly dependent timing
fields were changed:

- `pix_clk_hz = "56004480"`
- `min_framerate = "461432"`
- `max_framerate = "60000000"`
- `default_framerate = "60000000"`
- `min_exp_time = "34"`
- `max_exp_time = "2167163"`

### Fields Intentionally Left Unchanged

- `mclk_khz = "24000"`
- `mclk_multiplier = "2.43"`
- `serial_c`
- `port-index = 2`
- `num_lanes = 2`
- `lane_polarity = 0`
- `discontinuous_clk = "yes"`
- `cil_settletime = "0"`
- `embedded_metadata_height = "0"`

This keeps the retest focused on Sensor Pixel Clock only.

## Boot Staging

`ov5647-dev` was staged to boot the new overlay:

- `/boot/ov5647-p3768-port-c-reference-mclk24-pixclk56.dtbo`

Artifacts:

- `artifacts/boot/20260427T091439Z/extlinux.conf.generated`
- `logs/20260427T091439Z-switch_boot_profile.log`

Current intended default after reboot:

- `boot_profile=ov5647-dev`

## Current Interpretation

This is the narrowest remaining software-only retest that is still strongly
grounded in NVIDIA guidance:

- route and endpoint permutations are already exhausted;
- MCLK `25000` versus `24000` intent was already closed negatively;
- the sensor still remains in stream state through timeout;
- `pix_clk_hz` is now the one remaining capture-side DT value that is both:
  - read by NVIDIA runtime code;
  - demonstrably inconsistent with the current programmed `HTS/VTS`.

## Next Step

Reboot into the staged route-C `pixclk56` overlay, verify live DT shows:

- `pix_clk_hz = 56004480`
- `mclk_khz = 24000`
- `serial_c`
- `num_lanes = 2`

Then rerun the normal manual:

- `insmod full-delay-dump`
- RTCPU/NVCSI single-frame trace

and compare whether the failure class changes at all.
