# Clock And PM State Helper

Date: 2026-04-24

## Goal

Add a safe read-only snapshot for Jetson clock and power-domain state around
 failing OV5647 capture attempts.

## Added Helper

- `scripts/collect_clk_pm_state.sh`

It collects read-only snapshots from:

- `/sys/kernel/debug/clk/extperiph1`
- `/sys/kernel/debug/clk/nvcsi`
- `/sys/kernel/debug/clk/nvcsilp`
- `/sys/kernel/debug/clk/vi`
- `/sys/kernel/debug/pm_genpd/vi`
- `/sys/kernel/debug/pm_genpd/ispa`

Saved fields include:

- `clk_rate`
- `clk_parent`
- `clk_enable_count`
- `clk_prepare_count`
- `clk_protect_count`
- `clk_min_rate`
- `clk_max_rate`
- `current_state`
- `active_time`
- `total_idle_time`
- `devices`
- `sub_domains`

## Integration

`scripts/run_manual_single_frame_rtcpu_trace.sh` now calls the helper
automatically:

- before the capture attempt into `artifacts/traces/<ts>/clk-pm-before`
- after the capture attempt into `artifacts/traces/<ts>/clk-pm-after`

This keeps the clock/power-domain snapshot aligned with each traced capture
without adding a separate manual step.

## Standalone Validation

Standalone validation was run successfully:

```bash
sudo ./scripts/collect_clk_pm_state.sh \
  artifacts/clk-pm-state/20260424T080501Z-standalone
```

Artifacts:

- `artifacts/clk-pm-state/20260424T080501Z-standalone`
- `logs/20260424T080501Z-collect-clk-pm-standalone-wrapper.log`

Observed idle snapshot highlights:

- `extperiph1/clk_rate = 51000000`
- `extperiph1/clk_enable_count = 0`
- `nvcsi/clk_rate = 642900000`
- `vi/clk_rate = 832000000`
- `pm_genpd/vi/current_state = off-0`
- `pm_genpd/ispa/current_state = off-0`

## Practical Value

This does not prove the effective on-wire MCLK or CSI transport state.

It does give a reproducible Jetson-side snapshot to compare:

- before vs after a failed capture;
- one software branch vs another;
- idle state vs active attempted-stream state.
