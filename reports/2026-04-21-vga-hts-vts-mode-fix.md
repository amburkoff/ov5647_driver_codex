# 2026-04-21 VGA HTS/VTS Mode Fix

## Context

The LP-11 power-on fix executed but did not resolve the single-frame timeout. `VIDIOC_STREAMON` succeeds, but VI still receives no completed frame.

Codex did not run `insmod`, `rmmod`, capture, stream, or reboot for this checkpoint.

## Change

The 640x480 10-bit mode table now explicitly programs upstream OV5647 VGA timing:

- `HTS = 1852`:
  - `0x380c = 0x07`
  - `0x380d = 0x3c`
- `VTS = 0x01f8`:
  - `0x380e = 0x01`
  - `0x380f = 0xf8`

This is necessary because the local tegracam control callbacks are still stubs, while upstream Linux applies these timing values through V4L2 controls.

## Files Changed

- `src/nv_ov5647/nv_ov5647.c`

## Runtime Status

Not runtime-tested yet. The currently loaded kernel module is still the previous in-memory module until the user manually unloads and reloads the rebuilt `.ko`.

## Next Manual Test

After build and commit:

1. User manually unloads the current module.
2. User manually loads the rebuilt module with `full-delay`.
3. User manually runs one bounded single-frame capture.
