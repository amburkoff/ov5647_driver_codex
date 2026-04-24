# Clock And PM Runtime Observation 20260424T081333Z

Date: 2026-04-24

## Goal

Compare Jetson-side `clk` and `pm_genpd` state before and after a traced
OV5647 capture that still times out with `no SOF`.

## Commands Behind This Result

Manual commands run by user:

```bash
sudo /home/cam/ov5647_driver_codex/scripts/run_manual_insmod_diag.sh full-delay-dump
sudo /home/cam/ov5647_driver_codex/scripts/run_manual_single_frame_rtcpu_trace.sh
```

Trace directory:

- `artifacts/traces/20260424T081333Z`

## Trace Summary

The updated trace analyzer still reports:

- `receiver_signature=no_receiver_ingress_visible`

Control path is present, but receiver-side ingress events remain zero.

## Clock / PM Before-After Snapshot

Before capture:

- `extperiph1/clk_rate = 24000000`
- `extperiph1/clk_enable_count = 0`
- `extperiph1/clk_prepare_count = 0`
- `nvcsi/clk_enable_count = 0`
- `vi/clk_enable_count = 0`
- `pm_genpd/vi/current_state = off-0`
- `pm_genpd/vi/active_time = 0 ms`
- `pm_genpd/ispa/current_state = off-0`

After failed capture:

- `extperiph1/clk_rate = 24000000`
- `extperiph1/clk_enable_count = 0`
- `extperiph1/clk_prepare_count = 0`
- `nvcsi/clk_enable_count = 1`
- `vi/clk_enable_count = 0`
- `pm_genpd/vi/current_state = off-0`
- `pm_genpd/vi/active_time = 0 ms`
- `pm_genpd/ispa/current_state = off-0`

## Interpretation

This is not proof of a VI power bug by itself, because the snapshot is taken
after the userspace timeout and cleanup path has already run.

Still, it gives one useful Jetson-side signal:

- `nvcsi` clock bookkeeping changes during the failed capture attempt;
- `vi` clock bookkeeping does not show the same transition in the saved
  before/after snapshot;
- `pm_genpd/vi` remains reported as `off-0` in both snapshots.

## Practical Conclusion

The new helper does not overturn the main project conclusion, but it does refine
the picture:

- the failed stream attempt is not a total no-op inside the Jetson receiver
  stack, because `nvcsi` clock state changes;
- yet the capture still never reaches visible receiver-ingress events or frame
  start, and the saved post-attempt state still does not show `vi` as active.

This is consistent with the broader failure signature already established:

- sensor-side stream-on succeeds;
- NVCSI/VI handoff is initiated;
- valid frame ingress never becomes visible to the tracepoints.
