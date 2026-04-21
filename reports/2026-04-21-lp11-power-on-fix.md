# 2026-04-21 LP-11 Power-On Fix

## Context

The latest manual capture reached `VIDIOC_STREAMON`, but VI timed out without receiving frames. Probe, `/dev/video0`, media graph, start/stop callbacks, and module lifecycle were already working.

Codex did not run `insmod`, `rmmod`, capture, stream, or reboot for this checkpoint.

## Change

Added an upstream-aligned stream-stop register sequence during `ov5647_power_on()` immediately after sensor output-enable:

- `0x4800 = CLOCK_LANE_GATE | BUS_IDLE | CLOCK_LANE_DISABLE`
- `0x4202 = 0x0f`
- `0x300d = 0x01`

This mirrors the upstream OV5647 power-on intent: put CSI lanes into LP-11 before the first real stream start.

The same register sequence is now shared by `ov5647_stop_streaming()` to keep stop behavior consistent.

## Files Changed

- `src/nv_ov5647/nv_ov5647.c`

## Build Result

Build passed:

```text
[2026-04-21T15:24:12Z] Build finished
[2026-04-21T15:24:12Z] Artifacts saved under /home/cam/ov5647_driver_codex/artifacts/build/20260421T152410Z
```

`modinfo` passed and the built `.ko` contains:

```text
%s: stream-stop LP-11 setup complete
ov5647_write_stream_stop_regs
```

## Logs

- `logs/20260421T152251Z-upstream-power-reglists-reference.log`
- `logs/20260421T152303Z-upstream-enable-streams-reference.log`
- `logs/20260421T152406Z-diff-lp11-power-on-fix.log`
- `logs/20260421T152406Z-git-diff-check-lp11-power-on-fix.log`
- `logs/20260421T152406Z-source-after-lp11-power-on-fix.log`
- `logs/20260421T152410Z-build-module-lp11-power-on-fix.log`
- `logs/20260421T152427Z-modinfo-lp11-power-on-fix.log`
- `logs/20260421T152427Z-ko-strings-lp11-power-on-fix.log`

## Runtime Status

Not runtime-tested yet. The currently loaded kernel module is still the old in-memory module until the user manually unloads and reloads the rebuilt `.ko`.

## Next Manual Test

One command at a time:

1. User manually unloads the currently loaded module with the rmmod trace helper.
2. If unload returns cleanly, user manually loads the rebuilt module with `full-delay`.
3. If load returns cleanly, user manually runs the single-frame trace helper again.

If the capture still times out, the next source-only hypothesis is the 640x480 mode table mismatch against upstream Linux OV5647.
