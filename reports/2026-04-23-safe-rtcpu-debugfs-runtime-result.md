# Safe RTCPU Debugfs Runtime Result

Date: 2026-04-23

## Goal

Run the whitelisted `tegra_rtcpu_trace` debugfs reads after a known
`no SOF / zero-byte capture` state and check whether RTCPU retained any hidden
receiver-side exception or event signature.

## Command Run

```bash
sudo /home/cam/ov5647_driver_codex/scripts/run_manual_safe_rtcpu_debugfs_dump.sh
```

## Saved Artifacts

- `artifacts/rtcpu-debugfs/20260423T150751Z/pre-state.log`
- `artifacts/rtcpu-debugfs/20260423T150751Z/stats.log`
- `artifacts/rtcpu-debugfs/20260423T150751Z/last_exception.log`
- `artifacts/rtcpu-debugfs/20260423T150751Z/last_event.log`

## Result

The helper completed without crashing the kernel.

Key contents:

- `stats.log`
  - `Exceptions: 0`
  - `Events: 3`
- `last_exception.log`
  - empty
- `last_event.log`
  - `Len: 16`
  - `ID: 0x03010000`
  - `Start.`

## Interpretation

`0x03010000` matches the generic `camrtc_trace_type_start` event from
`camrtc-trace.h`:

- type `CAMRTC_EVENT_TYPE_START = 3`
- module `CAMRTC_EVENT_MODULE_BASE = 1`
- subid `0`

This means:

- RTCPU trace memory is alive and readable;
- there is no retained RTCPU exception for the current failure;
- the whitelisted debugfs view did not expose any additional receiver-side
  `NVCSI`, `VI`, or `capture` event beyond the generic trace start marker.

## Practical Conclusion

This narrows the value of the safe RTCPU debugfs path:

- it is useful as a low-risk sanity probe;
- it did **not** reveal a hidden camera-side failure signature for the current
  `no SOF` problem.

The main receiver-side evidence still comes from:

- traced capture logs;
- absence of `SOF/EOF` and `rtcpu_nvcsi_intr` activity;
- repeated VI timeout.
