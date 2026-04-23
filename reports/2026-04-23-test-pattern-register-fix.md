# OV5647 Test-Pattern Register Fix

Date: 2026-04-23

## Problem Found

The first local OV5647 test-pattern implementation used the wrong register map.

Observed on the first runtime:

- module parameter `ov5647_test_pattern=1` was loaded successfully;
- capture still timed out with no SOF;
- diagnostic readback showed the previous assumed test-pattern registers remained zero.

## Root Cause

The first implementation followed a community Nano-era hint too literally.

Primary-source review of upstream Linux OV5647 shows:

- test-pattern control register is `0x503d`
- values are:
  - `0x00` disabled
  - `0x80` color bars
  - `0x82` color squares
  - `0x81` random data

Reference:

- `drivers/media/i2c/ov5647.c` in upstream Linux
- saved note: `logs/*-upstream-test-pattern-reference.log`

## Fix Applied

- local driver now uses `0x503d` for OV5647 built-in test pattern
- diagnostic register dump now reads back `0x503d`
- earlier `0x0600/0x0601` assumption was removed from the active test-pattern path

## Build Result

- `./scripts/build_module.sh` completed successfully
- rebuilt module `srcversion`:
  - `A0015C1CFA665DFD8D8A041`

## Why This Matters

The previous synthetic-frame experiment was only partially informative:

- it still showed no SOF;
- but it did not prove that a real OV5647 built-in test image had been enabled.

This fix is required before the synthetic-frame branch can be judged fairly.

## Next Safe Step

- reboot once so the currently loaded older test-pattern module is gone
- manually load the corrected build
- run one traced single-frame capture

## Reboot Needed

- Yes
