# Route C Reset-Only Forced MCLK25 Timeout

Date: 2026-04-23

## What Was Tested

Live DT branch:

- `boot_profile=ov5647-dev`
- node `ov5647_c@36`
- `serial_c`
- `port-index = 2`
- `mclk_khz = 25000`
- `reset-gpios` present
- no `pwdn-gpios`

Manual runtime sequence:

```bash
sudo /home/cam/ov5647_driver_codex/scripts/run_manual_rmmod_trace.sh
sudo /home/cam/ov5647_driver_codex/scripts/run_manual_insmod_diag.sh full-delay-dump-mclk25
sudo /home/cam/ov5647_driver_codex/scripts/run_manual_single_frame_rtcpu_trace.sh
```

## What The Logs Show

- `rmmod rc=0`
- `insmod rc=0`
- module parameters included `mclk_override_hz=25000000`
- route-C parse_dt still resolves:
  - `reset_gpio=486`
  - `pwdn_gpio=-1`
- chip ID still reads as `0x5647`
- sensor still reaches:
  - `0x0100 = 0x01`
  - `0x4800 = 0x34`
- capture still ends with:
  - `VIDIOC_STREAMON returned 0`
  - raw output `0 bytes`
  - repeated `tegra-camrtc-capture-vi ... uncorr_err: request timed out after 2500 ms`

## Important Finding

Even with `mclk_override_hz=25000000`, the driver log still reports:

- `ov5647_power_on: mclk enabled rate=24000000`

So the previous `mclk_override_hz` implementation changed the requested software frequency
(`s_data->def_clk_freq`) but did not prove that the underlying clock object actually switched
from `24 MHz` to `25 MHz`.

## Interpretation

This closes the first route-C reset-only runtime branch:

- removing `pwdn`
- using `reset-gpios`
- selecting `serial_c`
- forcing `mclk_override_hz=25000000`

did not restore SOF or any frame ingress.

It also exposed a concrete software gap:

- `mclk_override_hz` needs explicit rate programming and logging on `pw->mclk`, not only
  `s_data->def_clk_freq` reassignment.

## Next Small Step

Patch the driver to:

- call `clk_set_rate(pw->mclk, mclk_override_hz)` explicitly;
- log the before/after rate;
- rebuild;
- repeat the same manual `route C + reset-only + mclk25` runtime sequence.
