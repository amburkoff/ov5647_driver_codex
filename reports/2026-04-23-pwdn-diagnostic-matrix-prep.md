# PWDN Diagnostic Matrix Prep

Date: 2026-04-23

## What Changed

- Added diagnostic module parameter `pwdn_mode`:
  - `0` = current/default behavior
  - `1` = inverted PWDN on power-on
  - `2` = ignore PWDN GPIO
- Added diagnostic module parameter `skip_board_setup_power_off`:
  - leaves the sensor powered after board-setup chip-id validation
  - intended to test whether the board-setup power cycle itself suppresses CSI bring-up on the current module path
- Added manual `insmod` profiles to `scripts/run_manual_insmod_diag.sh`:
  - `full-delay-dump-mclk24-pwdn-inverted`
  - `full-delay-dump-mclk24-pwdn-ignore`
  - `full-delay-dump-mclk24-pwdn-ignore-keep`
  - `full-delay-dump-mclk24-pwdn-inverted-keep`

## Build Result

- Module rebuild succeeded.
- New module `srcversion=246B8D72861E7177B779CB8`
- New `modinfo` parameters are visible:
  - `pwdn_mode`
  - `skip_board_setup_power_off`

## Why This Matters

Current evidence still allows one software-side hypothesis:

- on the native Pi Zero-style `22-pin` path, the Jetson `PWDN` line may actually land on a module-side `CAM_IO0` function rather than a true sensor `PWDN` input;
- repeated power cycling during `board_setup()` may also leave the module in a state where I2C still works but CSI transport never starts.

These new knobs let us test that hypothesis without changing DT or rewriting the core stream path again.

## Planned Manual Test Order

Run exactly one capture after each clean manual load:

1. `full-delay-dump-mclk24-pwdn-ignore`
2. `full-delay-dump-mclk24-pwdn-inverted`
3. `full-delay-dump-mclk24-pwdn-ignore-keep`
4. `full-delay-dump-mclk24-pwdn-inverted-keep`

Success criterion:

- any test that changes the result from `no SOF / 0 bytes` to a real frame or at least visible NVCSI/VI ingress events becomes the next branch to follow.

Failure criterion:

- if all four still produce the same `no SOF` signature, the remaining software-only room narrows further and the physical pinout/remap hypothesis becomes even stronger.
