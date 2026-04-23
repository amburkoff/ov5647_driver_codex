# OV5647 Test-Pattern Prep

Date: 2026-04-23

## What Changed

- Added a local OV5647 built-in test-pattern diagnostic path.
- Kept the experiment strictly LKM-only and runtime-only.
- Did not touch DT, boot profile, or overlay state.

## Files Changed

- `src/nv_ov5647/nv_ov5647.c`
- `scripts/run_manual_insmod_diag.sh`

## Implementation

- Added module parameter:
  - `ov5647_test_pattern`
  - values:
    - `0` = off
    - `1` = color bars
- Added OV5647 test-pattern register tables:
  - off: `0x0600=0x00`, `0x0601=0x00`
  - color bars: `0x0600=0x00`, `0x0601=0x02`
- Applied the test-pattern table in `ov5647_set_mode()` so it lives in the same mode context as the existing `640x480` path.
- Added `0x0600` and `0x0601` to the diagnostic stream-register dump.
- Added manual helper profile:
  - `full-delay-dump-mclk24-testpat`

## Build Result

- `./scripts/build_module.sh` completed successfully.
- Rebuilt module `modinfo` now shows:
  - `parm: ov5647_test_pattern`
- Rebuilt module `srcversion`:
  - `6E3B684D5BEDF0A0E024035`

## Why This Test Matters

Built-in sensor pattern is the strongest remaining software discriminator because it removes:

- optics
- focus
- scene brightness
- exposure realism

while keeping:

- the same I2C path
- the same mode programming path
- the same CSI transport path
- the same VI/NVCSI receive path

## Expected Interpretation

- If test pattern still gives no SOF:
  - treat physical CSI path / cable / pinout as the primary blocker.
- If test pattern gives SOF or frame data:
  - treat CSI transport as fundamentally alive;
  - move back to live-scene sensor-mode/image-path debugging.

## Next Manual Test

If `nv_ov5647` is not loaded:

```bash
sudo /home/cam/ov5647_driver_codex/scripts/run_manual_insmod_diag.sh full-delay-dump-mclk24-testpat
sudo /home/cam/ov5647_driver_codex/scripts/run_manual_single_frame_rtcpu_trace.sh
```

If `nv_ov5647` is already loaded, do not `insmod` again. First tell Codex the current module state so the next step stays safe.

## Reboot Needed

- No.
