# Route C Reset25 ClkSetRate Still 24MHz

Date: 2026-04-23

## What Was Tested

Runtime sequence on the already-booted route-C reset-only DT branch:

```bash
sudo /home/cam/ov5647_driver_codex/scripts/run_manual_rmmod_trace.sh
sudo /home/cam/ov5647_driver_codex/scripts/run_manual_insmod_diag.sh full-delay-dump-mclk25
sudo /home/cam/ov5647_driver_codex/scripts/run_manual_single_frame_rtcpu_trace.sh
```

Loaded module:

- `srcversion=64571279B7D881EB1BFF782`

## Key Findings

- `rmmod rc=0`
- `insmod rc=0`
- route-C reset-only semantics still active:
  - `reset_gpio=486`
  - `pwdn_gpio=-1`
- chip ID still reads:
  - `0x5647`
- sensor still reaches:
  - `0x0100 = 0x01`
  - `0x4800 = 0x34`
- capture still ends with:
  - `VIDIOC_STREAMON returned 0`
  - raw output `0 bytes`
  - repeated `uncorr_err: request timed out after 2500 ms`

## Crucial MCLK Result

The new explicit rate-programming log is now present:

- `clk_set_rate(25000000) ok rate 24000000 -> 24000000`

and the following lines still show:

- `enabling mclk def_clk_freq=25000000 current_rate=24000000`
- `mclk enabled rate=24000000`

So `mclk_override_hz=25000000` is now definitely reaching `clk_set_rate()`,
but the underlying `extperiph1` clock object still stays at `24 MHz`.

## Interpretation

This closes the remaining software-only uncertainty around the `25 MHz` route-C branch:

- the override path is no longer just a bookkeeping change;
- the kernel clock framework accepts the call but keeps the effective rate at `24 MHz`;
- the capture signature remains unchanged;
- there is still no sign of SOF or frame ingress at the receiver side.

## Practical Conclusion

At this point, all of the following have been tried without restoring frame ingress:

- route A
- route C
- lane polarity variants
- corrected MCLK binding
- explicit `cil_settletime`
- continuous and discontinuous MIPI clock paths
- upstream OV5647 test pattern
- `pwdn` diagnostics
- reset-only semantics
- explicit `clk_set_rate()` attempt to `25 MHz`

The dominant blocker remains the physical CSI path or carrier-specific routing mismatch, not an obvious remaining OV5647 register-path bug.
