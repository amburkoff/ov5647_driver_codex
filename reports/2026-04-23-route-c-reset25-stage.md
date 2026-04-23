# Route C Reset25 Stage

Date: 2026-04-23

## Why This Experiment

After:

- route A / route C attempts
- lane polarity tuning
- test pattern
- `PWDN/CAM_IO0` diagnostics
- explicit `cil_settletime = 58`

the remaining software-only room is narrow.

The most concrete external reference branch not yet tested in this repository is:

- route C
- reset-only control semantics
- `mclk_khz = 25000`

This branch comes from the reviewed shared Orin NX/P3768 OV5647 sample files.

## What Changes

New controlled overlay:

- `patches/ov5647-p3768-port-c-reset25-probe.dts`

Key differences versus the previous route-C probe overlay:

- `reset-gpios = <&gpio 0xa0 0>`
- no `pwdn-gpios`
- `mclk_khz = "25000"`
- `discontinuous_clk = "yes"`
- `mclk_multiplier = "2.33"`
- route remains `serial_c`, `port-index = 2`, `num_lanes = 2`

## Goal

This does not try to prove the shared sample is correct.

It tests one final high-value software-only branch:

- whether the current hardware behaves more like a reset-driven route-C design than like the route-A / pwdn-driven assumptions used so far.

## Success Criterion

- any change from the current `STREAMON ok + no SOF + 0 bytes` signature
- ideally `/dev/video0` plus at least some new NVCSI/VI ingress events, even if capture is not yet fully correct

## Failure Interpretation

If this branch still shows the same no-SOF signature, the remaining software-only search space becomes very small and the physical pinout/remap hypothesis becomes even stronger.
