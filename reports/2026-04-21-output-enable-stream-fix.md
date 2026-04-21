# 2026-04-21 OV5647 Output Enable Stream Fix

## Context

- previous manual capture reached driver `start_streaming`;
- output file was zero bytes;
- VI logged capture timeout;
- no risky runtime command was run for this checkpoint because the old full module is still loaded and `rmmod` is unsafe.

## Finding

Upstream Linux `drivers/media/i2c/ov5647.c` enables OV5647 output drivers during power-on:

- `0x3000 = 0x0f`
- `0x3001 = 0xff`
- `0x3002 = 0xe4`

It also disables them on power-off.

Our common register table set the same registers to zero and no later code re-enabled them. That can explain a clean software `STREAMING` transition with no MIPI data reaching VI.

Reference grep:

- `logs/20260421T094808Z-ov5647-output-enable-reference-grep.log`

## Change Prepared

- added `ov5647_sensor_oe_enable_regs`;
- added `ov5647_sensor_oe_disable_regs`;
- `ov5647_power_on()` now writes output-enable registers after power sequencing;
- `ov5647_power_off()` now tries to disable output drivers before GPIO/clock/regulator shutdown.

## Validation

- build passed:
  - `logs/20260421T094755Z-build_module-output-enable.log`
- `modinfo` passed:
  - `logs/20260421T094808Z-modinfo-output-enable.log`
- diff whitespace check passed:
  - `logs/20260421T094808Z-git-diff-check-output-enable.log`

## Runtime Status

- not loaded;
- not streamed;
- not captured;
- not unload-tested.

## Next Smallest Step

Keep this as the next runtime candidate. After the system is in a clean module state, load the rebuilt module and run one single-frame capture before changing DT or adding more mode-table fixes.
