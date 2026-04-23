# Test-Pattern Attempt Blocked By Loaded Module

Date: 2026-04-23

## What Happened

The first manual attempt to test OV5647 built-in color bars did not actually load the new test-pattern-capable module.

Commands run by the user:

```bash
sudo /home/cam/ov5647_driver_codex/scripts/run_manual_insmod_diag.sh full-delay-dump-mclk24-testpat
sudo /home/cam/ov5647_driver_codex/scripts/run_manual_single_frame_rtcpu_trace.sh
```

Observed result:

- `run_manual_insmod_diag.sh` refused `insmod` because `nv_ov5647` was already loaded;
- the subsequent capture still timed out with `rc=124` and raw size `0`.

## Why This Does Not Validate Test Pattern

Live module-state inspection after the failed `insmod` shows the loaded module parameters are:

- `allow_hw_probe=Y`
- `continuous_mipi_clock=N`
- `dump_stream_regs=Y`
- `mclk_override_hz=24000000`
- no `ov5647_test_pattern` parameter exists under `/sys/module/nv_ov5647/parameters/`

Implication:

- the loaded module instance predates commit `f2b6341`;
- the test-pattern-capable `.ko` was not inserted;
- capture `20260423T103838Z` is therefore not a valid test-pattern experiment.

## Current Result

- capture `20260423T103838Z` is another baseline no-SOF timeout, not a color-bar test;
- it does not change the current root-cause ranking.

## Helper Improvement Added

`scripts/run_manual_insmod_diag.sh` now prints loaded module parameters when it refuses `insmod` due to an already loaded `nv_ov5647`.

This makes stale-module situations explicit in future runs.

## Next Safe Step

To run a real test-pattern experiment, the currently loaded old module must be replaced by the rebuilt module from commit `f2b6341`.

Safer order of preference:

1. clean reboot, then load `full-delay-dump-mclk24-testpat`
2. manual `rmmod`, only if the user explicitly chooses that risk over reboot

## Reboot Needed

- Yes, if avoiding `rmmod` risk.
