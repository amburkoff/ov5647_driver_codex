# Route-C Capture-Side Assumptions Audit

Date: 2026-04-24

## Goal

Audit the remaining NVIDIA capture-side assumptions for the canonical OV5647
route-C baseline on Jetson Linux `r36.5`, and determine whether any route-C
DT-mode mismatch still looks strong enough to explain the current:

- `VIDIOC_STREAMON` success
- zero-byte raw capture
- repeated VI timeout
- no `SOF/EOF`
- no `rtcpu_nvcsi_intr`
- no `vi_frame_begin/end`

## Inputs

Canonical OV5647 route-C DT:

- `patches/ov5647-p3768-port-c-reference-mclk24.dts`

Official NVIDIA route-C references:

- `/boot/tegra234-p3767-camera-p3768-imx219-C.dtbo`
- `/boot/tegra234-p3767-camera-p3768-imx477-C.dtbo`

Official NVIDIA `r36.5` source checkout:

- `tools/vendor/linux-nv-oot-r36.5`

## What The NVIDIA Stack Actually Reads

### Endpoint-side fields

From:

- `drivers/media/platform/tegra/camera/vi/channel.c`
- `drivers/media/platform/tegra/camera/csi/csi.c`
- `drivers/media/platform/tegra/camera/camera_common.c`

The capture stack reads these endpoint properties for runtime binding:

- `port-index`
- `bus-width`
- optional `vc-id` (defaults to `0`)

### Mode-node signal fields

From:

- `drivers/media/platform/tegra/camera/sensor_common.c`

The mode parser reads and uses at runtime:

- `mclk_khz`
- `num_lanes`
- `pix_clk_hz`
- `csi_pixel_bit_depth`
- `cil_settletime`
- `lane_polarity`
- `discontinuous_clk`
- `tegra_sinterface`
- optional `embedded_metadata_height`

### Fields that are not meaningful runtime levers here

`mclk_multiplier` is required by NVIDIA's DT validation tests, but in the
official runtime code paths inspected here it is not consumed by the capture
stack the way `mclk_khz`, `pix_clk_hz`, or `num_lanes` are.

That means `mclk_multiplier` is not a strong runtime explanation for the
observed no-ingress failure class.

## Canonical Route-C Versus NVIDIA Route-C References

### Fields that already match the reference family

Canonical OV5647 route-C currently has:

- endpoint `port-index = 2`
- endpoint `bus-width = 2`
- `num_lanes = 2`
- `tegra_sinterface = "serial_c"`
- `phy_mode = "DPHY"`
- `cil_settletime = 0`
- `mclk_khz = 24000`
- `lane_polarity = 0`

This is already aligned with official NVIDIA route-C patterns:

- both `imx219-C` and `imx477-C` use:
  - `port-index = 2`
  - `bus-width = 2`
  - `num_lanes = 2`
  - `tegra_sinterface = "serial_c"`
  - `cil_settletime = 0`
  - `mclk_khz = 24000`
- `imx477-C` explicitly uses `lane_polarity = 0`
- `imx219-C` omits `lane_polarity`, which defaults to `0`

So these route-C capture-side fields are not currently suspicious.

### `discontinuous_clk`

Official NVIDIA route-C references show both patterns:

- `imx219-C`: `discontinuous_clk = "yes"`
- `imx477-C`: `discontinuous_clk = "no"`

Canonical OV5647 route-C uses:

- `discontinuous_clk = "yes"`

That already falls within NVIDIA's own observed route-C reference space and is
not an obvious standalone bug.

### `vc-id`

Canonical OV5647 route-C does not provide an explicit `vc-id`.

Runtime code in `vi/channel.c` defaults missing `vc-id` to:

- `0`

This is not suspicious by itself for a single-sensor single-stream bring-up.

### `embedded_metadata_height`

Canonical OV5647 route-C uses:

- `embedded_metadata_height = 0`

Official NVIDIA references often use:

- `embedded_metadata_height = 2`

But in the inspected runtime path this field is only used to size the embedded
metadata buffer in `vi5_fops.c` after sensor properties are parsed.

This means a mismatch here could affect metadata buffer allocation expectations,
but it does **not** explain a complete absence of:

- `SOF`
- `EOF`
- `rtcpu_nvcsi_intr`
- `vi_frame_begin/end`

So it is not a strong candidate for the current failure class.

## The One Remaining Capture-Side DT Assumption With Some Weight

The main route-C capture-side assumption that still matters at all is:

- `pix_clk_hz = 58333000`

Why it still matters:

- `sensor_common.c` converts `pix_clk_hz` and `csi_pixel_bit_depth` into
  `mipi_clock`
- `vi/channel.c` uses sensor pixel clock for device bandwidth / pixel-rate
  bookkeeping
- CSI deskew decisions also key off pixel clock

Why it still looks weaker than the hardware-path hypothesis:

- with `pix_clk_hz = 58.333 MHz`, the implied 2-lane, 10-bit aggregate rate is
  only about `291.665 Mbps`, far below the `deskew` threshold path;
- the route-C graph, lane count, port, polarity, and endpoint mapping are now
  already aligned with NVIDIA route-C reference patterns;
- the latest controlled `mclk24` retest still reproduced the exact same
  no-ingress signature.

So `pix_clk_hz` is the only remaining route-C capture-side DT assumption that
still has some software-only weight, but it is no longer a strong explanation
for a complete `no receiver ingress` result.

## Practical Conclusion

After this audit, the remaining route-C capture-side assumptions rank roughly
like this:

1. weak-to-moderate:
   - `pix_clk_hz` / sensor timing intent may still be imperfect
2. weak:
   - `embedded_metadata_height`
3. very weak:
   - `vc-id`
   - `discontinuous_clk`
   - `lane_polarity = 0`
   - `mclk_multiplier`

The stronger conclusion is negative:

- there is no obvious remaining NVIDIA capture-side route-C DT mismatch
  comparable in strength to:
  - a wrong `port-index`
  - a wrong `bus-width`
  - a wrong `tegra_sinterface`
  - a wrong lane count
  - a wrong MCLK intent

So the software-only route-C capture-side assumptions are now largely
exhausted, and the dominant blocker still looks more like:

- physical CSI link / pinout / orientation mismatch
- or deeper carrier-specific electrical routing not expressed by the current
  DT model
