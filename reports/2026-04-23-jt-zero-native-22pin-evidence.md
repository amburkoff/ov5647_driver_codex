# JT-ZERO Native 22-Pin Evidence

Date: 2026-04-23

## What Changed

- User provided top and bottom photos for `JT-ZERO-V2.0`.
- The photos were added to the repository:
  - `ov5647_JT-ZERO-V2.0_top.jpg`
  - `ov5647_JT-ZERO-V2.0_bottom.jpg`

## New Hardware Facts Confirmed

- `JT-ZERO-V2.0` is a native 22-pin OV5647 camera module.
- The module uses an integrated flex tail rather than a detachable camera cable.
- No inline `15->22` adapter board or detachable `15->22` conversion cable is visible in the photographed camera-side path.

## Why This Matters

- Raspberry Pi 22-pin CSI pinout is not same-numbered compatible with Jetson Orin Nano/NX `J20/J21` 22-pin camera pinout.
- Therefore a native Raspberry Pi Zero-style 22-pin camera does not become Jetson-compatible merely because the connector count and pitch are both `22-pin / 0.5 mm`.
- This photo evidence sharply raises the probability that the current no-SOF condition is caused by pinout/orientation incompatibility in the physical camera path.

## Current Interpretation

- The software path is now strong enough to prove:
  - probe succeeds;
  - chip ID `0x5647` is read;
  - media graph is created;
  - `VIDIOC_STREAMON` succeeds.
- The hardware path is still weak because:
  - neither route A nor route C produces any SOF;
  - RTCPU/NVCSI sees no receiver activity;
  - the camera module itself is now known to be a native Pi Zero-style 22-pin device.

## Next Smallest Step

- Prefer hardware correction or hardware falsification over more DT/register tuning:
  - document the Jetson-side insertion orientation with an in-situ photo, or
  - switch to a known-good Jetson-compatible camera/cable path, or
  - obtain a proven remap/adapter path specifically intended for Raspberry Pi Zero 22-pin cameras on Jetson Orin devkit-style 22-pin connectors.

## Reboot Needed

- No.
