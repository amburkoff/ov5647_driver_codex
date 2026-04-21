# CBL Carrier Mapping

Status: `partially verified, still carrier-identity blocked`

This document tracks only hardware facts that are confirmed for the actual target. Anything not verified from the running system, carrier documentation, or direct physical inspection stays marked as unresolved.

## Verified So Far

| Field | Status | Evidence |
| --- | --- | --- |
| SoM family | Confirmed | Live DT reports `p3767` Jetson Orin NX |
| Base carrier identity in live DT | Confirmed | Live DT reports `p3768-0000` NVIDIA Engineering Reference Developer Kit |
| Camera base I2C alias | Confirmed | `cam_i2c -> /bus@0/i2c@3180000` |
| Linux-visible base camera I2C bus | Confirmed | `i2c-2` maps to `3180000.i2c` |
| Active boot profile | Confirmed | `/proc/cmdline` contains `boot_profile=ov5647-dev` |
| Running camera overlay | Confirmed present | Live DT contains `cam_i2cmux` and `ov5647_a@36` |
| Reference 22-pin camera overlay family on disk | Confirmed | `imx219-A/C`, `imx477-A/C`, dual combinations in `/boot/` |
| Physical camera population | Confirmed | User reports identical OV5647 modules inserted into both Jetson 22-pin CSI connectors |
| Camera flex/module marking | Confirmed | User-reported marking: `JT-ZERO-V2.0 YH` |
| Live camera mux bus | Confirmed | `i2c-9` appears as downstream `i2c-2-mux (chan_id 0)` |
| Sensor I2C address | Confirmed | `i2cdetect -y 9` and `i2ctransfer` both see `0x36` |
| Sensor identity | Confirmed | Direct `i2ctransfer` returns chip ID `0x56 0x47` => `0x5647` |
| Live CSI route | Confirmed for current test path | Live sensor node uses `tegra_sinterface = "serial_b"` |
| Live CSI port index | Confirmed for current test path | Live endpoint graph uses route-A style `port-index = 1` |
| Live lane count | Confirmed for current test path | Live DT mode uses `num_lanes = "2"` and endpoint `bus-width = <2>` |
| Live lane polarity | Confirmed for current test path | Live DT mode uses `lane_polarity = "6"` |
| Live sensor node | Confirmed | `/bus@0/cam_i2cmux/i2c@0/ov5647_a@36` |
| Live PWDN GPIO | Confirmed from live DT | `pwdn-gpios = <... 0x3e 0>` => Linux GPIO `397` (`PH.06`) |
| Live reset GPIO | Confirmed absent in current node | No `reset-gpios` property on the active OV5647 probe node |
| Live MCLK source | Confirmed | Active OV5647 node carries `mclk = "extperiph1"` and `clocks = <&bpmp 0x07>` |
| Live regulators bound in DT | Confirmed names only | `avdd=vana`, `dvdd=vdig`, `iovdd=vif` |

## Not Yet Verified

| Field | Current state | Why it matters |
| --- | --- | --- |
| CBL carrier board identity and revision | Unresolved | The running system still identifies as NVIDIA `p3768`; this must be cross-checked against the physical board and any carrier EEPROM override |
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

These are useful design references for an OV5647 overlay skeleton, but they are not accepted as carrier truth until the actual CBL wiring is verified.

## Additional Physical Facts From User

- both Jetson 22-pin CSI connectors are populated with identical OV5647 modules;
- the visible marking on the camera flex/module is `JT-ZERO-V2.0 YH`;
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

Inference from these local references and the live successful probe:

- route `A` is the cleaner first candidate because two separate NVIDIA overlays agree on:
  - the mux leg
  - `serial_b`
  - `port-index = 1`
  - reset GPIO token `0x3e`
  - `lane_polarity = 6`
- route `C` remains plausible, but its lane-polarity handling is less uniform in the installed references.
- after repeated route-A capture timeouts, route `C` is now the next controlled overlay experiment:
  - `cam_i2cmux/i2c@1`;
  - `serial_c`;
  - `port-index = 2`;
  - reset/PWDN GPIO token `0xa0`;
  - lane polarity candidate `0`.

## Current Live Working Probe Facts

- active sensor path in live DT:
  - `cam_i2cmux/i2c@0/ov5647_a@36`
- active logical camera route:
  - route `A`
  - `serial_b`
  - `port-index = 1`
  - `bus-width = <2>`
  - `lane_polarity = "6"`
- active I2C path:
  - base controller `3180000.i2c` as Linux `i2c-2`
  - muxed downstream bus `i2c-9`
  - sensor address `0x36`
- direct hardware confirmation:
  - `sudo i2ctransfer -f -y 9 w2@0x36 0x30 0x0a r1` -> `0x56`
  - `sudo i2ctransfer -f -y 9 w2@0x36 0x30 0x0b r1` -> `0x47`
- current driver-specific power observation:
  - with the current camera path, chip-ID reads failed when `ov5647_power_on()` drove `pwdn_gpio=397` low;
  - chip-ID reads succeeded when `ov5647_power_on()` kept `pwdn_gpio=397` high;
  - this means the present path should currently be treated as `pwdn deasserted high` until carrier wiring proves otherwise.

## Blocking Next Checks

1. Inspect the physical carrier board silkscreen and connector labels.
2. Record the exact FFC cable and any adapter board between the carrier and OV5647 module.
3. Confirm whether the carrier exposes Jetson devkit-style 22-pin connectors or a custom route.
4. Map the physical connector the user actually used to the now-confirmed live logical route `A`.
5. Keep the bring-up focused on this one confirmed route while raw capture is established.
6. If route-C is tested, treat it as a separate boot-profile experiment and compare probe, media graph, and capture behavior against route A.
