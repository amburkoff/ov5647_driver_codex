# Route-A Lane-Polarity-0 Boot Stage

Date: 2026-04-23

## Goal

Stage one reboot-only DT experiment after the matched non-continuous-clock route-A test still produced no SOF.

## Change

- New overlay source: `patches/ov5647-p3768-port-a-lanepol0-probe.dts`.
- Built artifact: `artifacts/dtbo/20260423T080742Z-ov5647-p3768-port-a-lanepol0-probe.dtbo`.
- Installed boot copy: `/boot/ov5647-p3768-port-a-lanepol0.dtbo`.
- Updated boot config:
  - `DEFAULT ov5647-dev`
  - `OVERLAYS /boot/ov5647-p3768-port-a-lanepol0.dtbo`
  - safe profile preserved unchanged.

## Single Controlled Variable

Relative to the current route-A overlay line, this staged overlay changes only:

- `lane_polarity = "0"` instead of `lane_polarity = "6"`.

I2C path, `serial_b`, `port-index = 1`, lane count, clock binding, and sensor mode remain unchanged.

## Why This Is Next

The last two route-A captures both reached `VIDIOC_STREAMON`, both programmed the expected sensor registers, and both timed out with no SOF/NVCSI/vinotify events:

- continuous-clock diagnostic: `0x4800 = 0x04`
- matched non-continuous diagnostic: `0x4800 = 0x34`

That rules out the continuous-clock mismatch as the simplest explanation and makes lane polarity or physical lane routing the next smallest software variable.

## Required Next Action

Reboot into the already-staged dev profile, then verify:

1. `/proc/cmdline` still reports `boot_profile=ov5647-dev`
2. live DT exposes route A with `lane_polarity = "0"`
3. only then run the next manual `insmod` and traced single-frame capture
