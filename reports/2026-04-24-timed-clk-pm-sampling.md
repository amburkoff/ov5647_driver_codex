# Timed Clock And PM Sampling

Date: 2026-04-24

## Goal

Refine the Jetson-side clock/power observation from simple `before/after`
 snapshots to timed sampling during the 30-second userspace capture timeout.

## Change

`scripts/run_manual_single_frame_rtcpu_trace.sh` now starts a background
sampler while `v4l2-ctl` is running.

The sampler:

- calls `scripts/collect_clk_pm_state.sh`
- defaults to `CLK_PM_SAMPLE_INTERVAL_SEC=1`
- writes snapshots under:
  - `artifacts/traces/<timestamp>/clk-pm-samples/sample-0000`
  - `artifacts/traces/<timestamp>/clk-pm-samples/sample-0001`
  - ...

## Why

The earlier `before/after` snapshot for `20260424T081333Z` showed:

- `nvcsi/clk_enable_count` changed from `0` to `1`
- `vi/clk_enable_count` stayed `0`
- `pm_genpd/vi/current_state` stayed `off-0`

But that observation was still coarse, because it was captured only after the
timeout and cleanup path.

Timed sampling is meant to answer one narrower question:

- does `vi` ever become active briefly during the failed capture attempt, then
  fall back to idle before the final snapshot is taken?

## Expected Next Manual Step

Run one more traced capture with the updated script. The new sample directories
will then show whether `vi`/`nvcsi`/`extperiph1` change transiently during the
timeout window.
