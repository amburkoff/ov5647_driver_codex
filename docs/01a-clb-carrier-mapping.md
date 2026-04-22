# CLB Carrier Mapping

Status: `partially verified, route-C live, still carrier-identity blocked`

This document tracks only hardware facts that are confirmed for the actual target. Anything not verified from the running system, carrier documentation, or direct physical inspection stays marked as unresolved.

## Verified So Far

| Field | Status | Evidence |
| --- | --- | --- |
| SoM family | Confirmed | Live DT reports `p3767` Jetson Orin NX |
| Base carrier identity in live DT | Confirmed | Live DT reports `p3768-0000` NVIDIA Engineering Reference Developer Kit |
| Camera base I2C alias | Confirmed | `cam_i2c -> /bus@0/i2c@3180000` |
| Linux-visible base camera I2C bus | Confirmed | `i2c-2` maps to `3180000.i2c` |
| Active boot profile | Confirmed | `/proc/cmdline` contains `boot_profile=ov5647-dev` |
| Running camera overlay | Confirmed present | Live DT contains `cam_i2cmux` and active `ov5647_c@36` |
| Reference 22-pin camera overlay family on disk | Confirmed | `imx219-A/C`, `imx477-A/C`, dual combinations in `/boot/` |
| Physical camera population | Confirmed | User reports identical OV5647 modules inserted into both Jetson 22-pin CSI connectors |
| Camera flex/module marking | Confirmed | User-reported marking: `JT-ZERO-V2.0 YH` |
| Corrected carrier name | Confirmed from user physical inspection | User corrected the kit name to `CLB Developer Kit`; earlier project notes used a mistyped carrier name |
| Partner/vendor marking | Confirmed from user physical inspection | User reports the box says the board is from partner `makerobo` |
| Bundled booklet flashing instruction | Confirmed from user physical inspection | User reports the booklet says to install the Jetson image from the official Developer Kit site |
| Live camera mux bus | Confirmed | `i2c-9` appears as downstream `i2c-2-mux`; current route-C boot maps it to `chan_id 1` |
| Sensor I2C address | Confirmed | `i2cdetect -y 9` and `i2ctransfer` both see `0x36` |
| Sensor identity | Confirmed | Direct `i2ctransfer` returns chip ID `0x56 0x47` => `0x5647` |
| Live CSI route | Confirmed for current test path | Live sensor node uses `tegra_sinterface = "serial_c"` |
| Live CSI port index | Confirmed for current test path | Live endpoint graph uses route-C style `port-index = 2` |
| Live lane count | Confirmed for current test path | Live DT mode uses `num_lanes = "2"` and endpoint `bus-width = <2>` |
| Live lane polarity | Confirmed for current test path | Live DT mode uses `lane_polarity = "0"` |
| Live discontinuous clock mode | Confirmed for current test path | Live DT mode uses `discontinuous_clk = "no"` |
| Live sensor node | Confirmed | `/bus@0/cam_i2cmux/i2c@1/ov5647_c@36` |
| Live PWDN GPIO | Confirmed from live DT and driver logs | `pwdn-gpios = <... 0xa0 0>` => Linux GPIO `486` |
| Live reset GPIO | Confirmed absent in current node | No `reset-gpios` property on the active OV5647 probe node |
| Live MCLK source | Confirmed | Active OV5647 node carries `mclk = "extperiph1"` and `clocks = <&bpmp 0x07>` |
| Live regulators bound in DT | Confirmed names only | `avdd=vana`, `dvdd=vdig`, `iovdd=vif` |

## Not Yet Verified

| Field | Current state | Why it matters |
| --- | --- | --- |
| CLB carrier board identity and revision | Partially resolved | User confirms CLB Developer Kit and `makerobo` partner box; board revision and schematic-level camera routing remain unresolved |
| Physical CSI connector in use | Unresolved | Needed before choosing A vs C vs any carrier-specific route |
| Exact adapter/cable type behind `JT-ZERO-V2.0 YH` | Unresolved | The marking suggests Raspberry Pi-market OV5647 hardware, but the exact Jetson-side cable/adaptor chain is still not verified |
| Physical CSI connector label on the carrier | Unresolved | Live DT confirms the logical route, but not the silkscreened connector name the user physically used |
| Sensor-side cable or adapter path | Unresolved | Required to avoid connector-orientation mistakes |
| Physical cable / adapter orientation | Unresolved | The user confirmed only the flex marking, not the adapter topology into the carrier |
| Reset GPIO on the actual module path | Unresolved | Current working probe path uses no reset GPIO, but this still needs carrier/schematic confirmation |
| Real powered rails behind `vana/vdig/vif` | Unresolved | Driver currently receives dummy regulators, so the rail names are DT-level facts, not electrical proof |
| EEPROM presence | Unresolved | Affects module table and possible camera module metadata |

## Working Reference, Not Ground Truth

The NVIDIA p3768 reference overlays on disk imply two common 22-pin connector routes:

- connector `A`: `serial_b`, `port-index = 1`, `cam_i2cmux/i2c@0`
- connector `C`: `serial_c`, `port-index = 2`, `cam_i2cmux/i2c@1`

These are useful design references for an OV5647 overlay skeleton, but they are not accepted as carrier truth until the actual CLB wiring is verified.

The official NVIDIA Jetson Orin Nano Developer Kit carrier board specification is also used as reference only: it documents two 22-pin camera connectors, with J20 on the first CAM I2C mux output and J21 on the second CAM I2C mux output. That supports the local p3768 overlay interpretation, but it still does not prove that the CLB Developer Kit carrier, cable, and Raspberry Pi-style module path are electrically identical.

The user's bundled booklet instruction to use the official Jetson Developer Kit image explains why the running software identifies as NVIDIA `p3768` rather than a CLB-specific DT. It does not remove the need to verify the physical CLB CSI connector routing, because the camera connector wiring can still differ from the reference carrier or depend on cable orientation/adapters.

## 22-Pin Connector Compatibility Risk

The current camera modules are Raspberry Pi-market OV5647 modules with visible marking `JT-ZERO-V2.0 YH`. The official reference pinouts show that a Jetson developer-kit 22-pin camera connector and a Raspberry Pi Zero/CM-style 22-pin camera connector are not directly pin-compatible by same-numbered pins:

| Pin group | NVIDIA Orin Nano developer carrier reference | Raspberry Pi official 22-pin CSI reference |
| --- | --- | --- |
| Power | pin 1 is `+3.3V` | pin 22 is `3V3`, pin 1 is `GND` |
| I2C | pins 2/3 are `CAM_I2C_SDA/SCL` | pins 21/20 are `SDA/SCL` |
| Control/clock | pins 5/6 are `CAM0_MCLK/CAM0_PWDN` on J20 | pins 18/17 are `CAM_IO1/CAM_IO0` |
| CSI lanes | Jetson reference places CSI pairs across pins 8-15 and 17-21 depending connector/route | Raspberry Pi reference places D0/D1/CLK on pins 2-9 for the first two-lane path |

Implication:

- A correct cable/adaptor can intentionally reverse or remap the flex so these signals line up.
- A wrong same-side 22-pin FFC orientation can leave power/I2C partially plausible while CSI data/clock lanes are wrong.
- Successful I2C chip-ID on `0x36` therefore does not prove the MIPI CSI lane mapping is correct.
- The current no-SOF trace is consistent with a wrong physical CSI lane path, even though probe and `VIDIOC_STREAMON` succeed.

Reference sources:

- NVIDIA Jetson Orin Nano Developer Kit carrier board specification, camera connector pin descriptions.
- NVIDIA Jetson Orin Nano Developer Kit User Guide, CSI camera hardware connection and bottom-contact note.
- Raspberry Pi official 22-pin camera connector pinout.

## Additional Physical Facts From User

- both Jetson 22-pin CSI connectors are populated with identical OV5647 modules;
- the visible marking on the camera flex/module is `JT-ZERO-V2.0 YH`;
- the kit name is `CLB Developer Kit`;
- the box identifies the board as a partner board from `makerobo`;
- the included booklet instructs installing the official Jetson Developer Kit image;
- this is consistent with Raspberry Pi-market OV5647 hardware, but it does not by itself identify:
  - the exact FFC pinout presented to the carrier,
  - whether any adapter board is inline,
  - which physical connector should be treated as the first single-sensor milestone path.

## Strongest Current Reference Evidence

From the locally installed NVIDIA p3768 overlays:

### Route A

- `imx219-A`
  - `cam_i2cmux/i2c@0`
  - `tegra_sinterface = "serial_b"`
  - `port-index = 1`
  - `bus-width = 2`
  - `reset-gpios = <... 0x3e ...>`
  - `lane_polarity = "6"`
- `imx477-A`
  - `cam_i2cmux/i2c@0`
  - `tegra_sinterface = "serial_b"`
  - `port-index = 1`
  - `bus-width = 2`
  - `reset-gpios = <... 0x3e ...>`
  - `lane_polarity = "6"`

### Route C

- `imx219-C`
  - `cam_i2cmux/i2c@1`
  - `tegra_sinterface = "serial_c"`
  - `port-index = 2`
  - `bus-width = 2`
  - `reset-gpios = <... 0xa0 ...>`
  - no explicit `lane_polarity` seen in the decompiled overlay excerpt
- `imx477-C`
  - `cam_i2cmux/i2c@1`
  - `tegra_sinterface = "serial_c"`
  - `port-index = 2`
  - `bus-width = 2`
  - `reset-gpios = <... 0xa0 ...>`
  - `lane_polarity = "0"`

Inference from these local references and the live successful probes:

- route `A` was the cleaner first candidate because two separate NVIDIA overlays agree on:
  - the mux leg
  - `serial_b`
  - `port-index = 1`
  - reset GPIO token `0x3e`
  - `lane_polarity = 6`
- route `C` became the second controlled overlay experiment after repeated route-A capture timeouts:
  - `cam_i2cmux/i2c@1`;
  - `serial_c`;
  - `port-index = 2`;
  - reset/PWDN GPIO token `0xa0`;
  - lane polarity candidate `0`.
- route `C` has now probe-validated and stream-attempted:
  - Linux downstream bus `i2c-9`;
  - sensor address `0x36`;
  - chip ID `0x5647`;
  - Linux PWDN GPIO `486`;
  - VI route `platform:tegra-capture-vi:2`;
  - `/dev/video0` created.
- route `C` still does not deliver frames:
  - `VIDIOC_STREAMON` returns success;
  - raw output remains zero bytes;
  - RTCPU/NVCSI tracing shows no SOF, no EOF, no NVCSI interrupt, and no vinotify error in the capture window.

## Current Live Working Probe Facts

- active sensor path in live DT:
  - `cam_i2cmux/i2c@1/ov5647_c@36`
- active logical camera route:
  - route `C`
  - `serial_c`
  - `port-index = 2`
  - `bus-width = <2>`
  - `lane_polarity = "0"`
  - `discontinuous_clk = "no"`
- active I2C path:
  - base controller `3180000.i2c` as Linux `i2c-2`
  - muxed downstream bus `i2c-9`
  - sensor address `0x36`
- direct hardware confirmation:
  - `sudo i2ctransfer -f -y 9 w2@0x36 0x30 0x0a r1` -> `0x56`
  - `sudo i2ctransfer -f -y 9 w2@0x36 0x30 0x0b r1` -> `0x47`
- current driver-specific power observation:
  - with the earlier route-A path, chip-ID reads failed when `ov5647_power_on()` drove `pwdn_gpio=397` low;
  - chip-ID reads succeeded when `ov5647_power_on()` kept `pwdn_gpio=397` high;
  - route-C uses `pwdn_gpio=486` with the same deassert-high driver policy;
  - this means the present path should currently be treated as `pwdn deasserted high` until carrier wiring proves otherwise.

## Current No-SOF Evidence

The latest route-C continuous-clock runtime test proves that the Linux/V4L2 path reaches stream start but no frame start reaches NVCSI/VI:

- `VIDIOC_STREAMON` returns success;
- register readback after stream-on confirms `0x0100 = 0x01`;
- output-enable readback confirms `0x3000 = 0x0f`, `0x3001 = 0xff`, `0x3002 = 0xe4`;
- MIPI clock register readback confirms the continuous-clock diagnostic value `0x4800 = 0x04`;
- after the clock-ID fix, driver logs confirm `extperiph1` MCLK is enabled at `24000000` Hz;
- RTCPU/NVCSI trace contains no `vi_frame_begin`, `vi_frame_end`, `rtcpu_nvcsi_intr`, `rtcpu_vinotify_error`, `capture_event_sof`, or `capture_event_error`.

This does not prove the sensor is incapable of output. It proves that the current DT route, physical lane path, cable/adapter path, or MIPI electrical output state is still not producing an observable SOF at the Jetson receiver. Because the earlier route-A test used the old wrong BPMP clock binding, one corrected-MCLK route-A retest is still a valid controlled software experiment before treating the issue as purely physical.

## Blocking Next Checks

1. Inspect the physical carrier board silkscreen and connector labels.
2. Record the exact FFC cable and any adapter board between the carrier and OV5647 module.
3. Confirm whether the carrier exposes Jetson devkit-style 22-pin connectors or a custom route.
4. Map each physical connector to the observed route-A and route-C logical paths.
5. Verify whether the `JT-ZERO-V2.0 YH` Raspberry Pi-style OV5647 flex/module path is pin-compatible with the CLB/Jetson 22-pin connector orientation.
6. Do not continue blind stream-register tuning until the physical CSI lane path or a known-good Jetson camera module cross-check is available.
