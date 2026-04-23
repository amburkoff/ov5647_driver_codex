# GiraffAI And digitallyamar OV5647 Review

Date: 2026-04-23

## Scope

Reviewed:

- GiraffAI Jetson Nano OV5647 article series
- GitHub repository `digitallyamar/ov5647`

Saved raw review logs:

- `logs/20260423T094500Z-giraffai-articles-review.html`
- `logs/20260423T094500Z-digitallyamar-ov5647-review.txt`
- `logs/20260423T094500Z-local-test-pattern-gap-review.log`

## What Is Transferable

### 1. Built-in sensor test pattern is the best next software test

The most useful idea from their work is not their Nano DT layout. It is their milestone order:

1. detect chip ID over I2C;
2. confirm the sensor is alive;
3. generate OV5647 test images from the sensor itself;
4. only after that trust live optical capture.

Their repo includes test-pattern registers in `ov5647_modes_tbls.h`:

- `0x0600`
- `0x0601`

Their article sequence explicitly says they used OV5647-generated test images before live capture.

Why this matters for us:

- a built-in test pattern removes optics, focus, scene brightness, and Bayer conversion from the first question;
- if the receiver still sees no SOF with test pattern enabled, then the current blocker is almost certainly the CSI electrical/pinout path;
- if test pattern works, then the CSI route is fundamentally alive and we can move back to mode-table/image-path debugging.

### 2. Chip-ID plus `STREAMON` is not enough

Their articles reinforce a point already visible in our logs:

- chip-ID only proves I2C, some power, and some clock/control path;
- it does not prove that valid MIPI frames are reaching NVCSI.

That matches our current no-SOF condition exactly.

## What Is Not Transferable Directly

### 1. Nano DT routing

Their DT is for Jetson Nano / `tegra210` and uses:

- `serial_a`
- `port-index = 0`
- Nano camera topology

This does not map directly onto our Orin NX / CLB route-A and route-C experiments.

### 2. Camera connector assumptions

Their project assumes a Nano-compatible Raspberry Pi camera path.

Our current confirmed hardware facts are different:

- carrier is CLB/makerobo, not Nano;
- SoM is Orin NX on a p3768-flashed software stack;
- current `JT-ZERO-V2.0` camera is a native 22-pin Pi Zero-style module, not a standard 15-pin Raspberry Pi camera using a known-good `15->22` Jetson conversion cable.

So their success does not reduce our pinout-risk the way it would for a normal Jetson-compatible camera kit.

### 3. Some repo code quality is not strong enough to copy blindly

The repo is useful as a hint source, but not as a source of truth for our port:

- it is older Nano-era tegracam code;
- several callbacks are stubs;
- `ov5647_write_reg()` in that tree is not a useful implementation reference;
- their DT/module integration details are not appropriate for Orin `r36.5`.

## New Ideas Worth Testing

### Highest priority software test

Implement a controlled built-in OV5647 test-pattern path in the local Orin driver:

- add a gated diagnostic control or module parameter;
- write OV5647 test-pattern registers:
  - `0x0600`
  - `0x0601`
- keep the rest of the route and mode identical to the current `640x480` path;
- run exactly one traced capture.

Interpretation:

- if `no SOF` persists, stop spending time on mode-table polish and treat hardware path as the blocker;
- if frames arrive, continue software bring-up from that working synthetic-frame baseline.

### Secondary, lower-value software ideas

- compare whether `embedded_metadata_height = 0` vs `2` changes anything.
- compare whether Bayer phase should be `rggb` instead of current `bggr`.

Why these are secondary:

- they might affect image interpretation or buffer layout;
- they are poor explanations for the current complete lack of SOF/NVCSI events.

## Current Best Explanation

The review strengthens, not weakens, the current main hypothesis:

- our driver reaches probe and stream state;
- our current physical camera is a native Pi Zero-style 22-pin module;
- our receiver still sees no SOF on every tested route;
- therefore physical CSI path / cable / pinout incompatibility remains the leading cause.

## Recommended Next Step

Best next software step:

- implement OV5647 built-in test-pattern support and run one traced capture.

Best next hardware step in parallel:

- verify in-situ connector orientation or switch to a proven Jetson-compatible camera/cable path.
