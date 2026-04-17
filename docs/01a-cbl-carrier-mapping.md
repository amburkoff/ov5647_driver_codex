# CBL Carrier Mapping

Status: `partially blocked`

This document tracks only hardware facts that are confirmed for the actual target. Anything not verified from the running system, carrier documentation, or direct physical inspection stays marked as unresolved.

## Verified So Far

| Field | Status | Evidence |
| --- | --- | --- |
| SoM family | Confirmed | Live DT reports `p3767` Jetson Orin NX |
| Base carrier identity in live DT | Confirmed | Live DT reports `p3768-0000` NVIDIA Engineering Reference Developer Kit |
| Camera base I2C alias | Confirmed | `cam_i2c -> /bus@0/i2c@3180000` |
| Linux-visible base camera I2C bus | Confirmed | `i2c-2` maps to `3180000.i2c` |
| Running camera overlay | Confirmed absent | No live `cam_i2cmux` or sensor nodes found |
| Reference 22-pin camera overlay family on disk | Confirmed | `imx219-A/C`, `imx477-A/C`, dual combinations in `/boot/` |

## Not Yet Verified

| Field | Current state | Why it matters |
| --- | --- | --- |
| CBL carrier board identity and revision | Unresolved | The running system still identifies as NVIDIA `p3768`; this must be cross-checked against the physical board and any carrier EEPROM override |
| Physical CSI connector in use | Unresolved | Needed before choosing A vs C vs any carrier-specific route |
| Live CSI port for the connected OV5647 | Unresolved | Needed for `port-index`, `tegra_sinterface`, and endpoint graph |
| Sensor-side cable or adapter path | Unresolved | Required to avoid connector-orientation mistakes |
| Actual sensor I2C address | Unresolved | Must be confirmed from hardware and probe results, not assumed |
| Reset GPIO | Unresolved | Must be confirmed from carrier wiring or working reference design |
| PWDN GPIO | Unresolved | Must be confirmed from carrier wiring or working reference design |
| MCLK source and rate | Unresolved | Required for both DT and power-on sequencing |
| Regulator names and voltage rails | Unresolved | Required for safe power sequencing and unwind |
| Lane count and lane polarity | Unresolved for the real sensor | Project target is 2-lane, but this must be confirmed against the real link |
| EEPROM presence | Unresolved | Affects module table and possible camera module metadata |

## Working Reference, Not Ground Truth

The NVIDIA p3768 reference overlays on disk imply two common 22-pin connector routes:

- connector `A`: `serial_b`, `port-index = 1`, `cam_i2cmux/i2c@0`
- connector `C`: `serial_c`, `port-index = 2`, `cam_i2cmux/i2c@1`

These are useful design references for an OV5647 overlay skeleton, but they are not accepted as carrier truth until the actual CBL wiring is verified.

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

Inference from these local references:

- route `A` is the cleaner first candidate because two separate NVIDIA overlays agree on:
  - the mux leg
  - `serial_b`
  - `port-index = 1`
  - reset GPIO token `0x3e`
  - `lane_polarity = 6`
- route `C` remains plausible, but its lane-polarity handling is less uniform in the installed references.

## Blocking Next Checks

1. Inspect the physical carrier board silkscreen and connector labels.
2. Record the exact FFC cable and any adapter board between the carrier and OV5647 module.
3. Confirm whether the carrier exposes Jetson devkit-style 22-pin connectors or a custom route.
4. After the physical route is known, bind it to one live DT port and one camera I2C path.
5. Only then choose the first OV5647 overlay target and the first probe attempt.
