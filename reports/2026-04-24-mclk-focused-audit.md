# MCLK Focused Audit

Date: 2026-04-24

## Goal

Audit the canonical route-C `mclk` path end to end:

- DT intent
- NVIDIA framework propagation
- local driver behavior
- runtime clock result

and estimate whether the current `25000 kHz intent -> 24000000 Hz runtime`
mismatch is still a strong candidate for the observed full `no receiver ingress`
failure.

## Source Path

Canonical route-C DT source:

- `patches/ov5647-p3768-port-c-reference.dts`

Relevant local driver path:

- `src/nv_ov5647/nv_ov5647.c`

Relevant NVIDIA framework path from official `linux-nv-oot-r36.5`:

- `drivers/media/platform/tegra/camera/sensor_common.c`
- `drivers/media/platform/tegra/camera/tegracam_core.c`
- `drivers/media/platform/tegra/camera/camera_common.c`

## What The Stack Does

### 1. DT intent

Canonical route-C overlay currently declares:

- `mclk = "extperiph1"`
- `clock-names = "extperiph1"`
- `clocks = <&bpmp 0x24>`
- `mode0/mclk_khz = "25000"`

### 2. NVIDIA framework parsing

Official NVIDIA source shows:

- `sensor_common_parse_signal_props()` reads `mclk_khz`
  into `signal_properties.mclk_freq`
- `tegracam_device_register()` then sets:
  - `s_data->def_clk_freq = signal_props->mclk_freq * 1000`
- `camera_common_mclk_enable()` always does:
  - `clk_set_rate(pw->mclk, s_data->def_clk_freq)`
  - `clk_prepare_enable(pw->mclk)`

So the DT value is not just documentation. It is the framework's intended
runtime clock request.

### 3. Local driver behavior

The local driver preserves that path and adds diagnostics:

- `ov5647_power_get()` logs:
  - acquired clock name
  - current clock rate
  - current `def_clk_freq`
- `ov5647_power_on()` logs:
  - requested `def_clk_freq`
  - optional `mclk_override_hz`
  - actual `clk_set_rate()` result
  - actual enabled clock rate

The local diagnostic override does two things:

- rewrites `s_data->def_clk_freq`
- explicitly calls `clk_set_rate(pw->mclk, mclk_override_hz)` before the normal
  `camera_common_mclk_enable()`

## Runtime Facts

Observed on canonical route-C baseline and on earlier route-C reset-only
variants:

- DT intent:
  - `mclk_khz = 25000`
- runtime request:
  - `def_clk_freq = 25000000`
- effective result:
  - `mclk enabled rate = 24000000`

Even with explicit override and direct `clk_set_rate(25000000)`, runtime logged:

- `clk_set_rate(25000000) ok rate 24000000 -> 24000000`

So on this platform path, `extperiph1` is effectively staying at `24 MHz`.

## Comparison With Official NVIDIA Route-C Overlays

Official NVIDIA route-C references on the same platform family:

- `/boot/tegra234-p3767-camera-p3768-imx219-C.dtbo`
- `/boot/tegra234-p3767-camera-p3768-imx477-C.dtbo`

both declare:

- `mclk_khz = "24000"`

So the canonical OV5647 route-C baseline is currently unusual relative to
official NVIDIA route-C examples only in the *intent* value `25000`, not in the
actual enabled runtime clock, which still lands at `24000000`.

## Assessment

### What this weakens

This weakens the hypothesis that a hidden clock-framework bug is the main
explanation for the failure.

Reason:

- the Jetson clock framework path is functioning:
  - `devm_clk_get()` succeeds
  - `clk_set_rate()` is called
  - `camera_common_mclk_enable()` succeeds
  - `mclk` is enabled

### What remains possible

It does **not** fully eliminate `mclk` as a contributing factor.

There is still a real mismatch between:

- route-C DT intent `25000`
- actual runtime `24000000`

Inference:

- if OV5647 mode timing or internal PLL assumptions were built around `25 MHz`,
  then actual sensor output timing could shift by roughly 4%.
- that could affect the true CSI line rate relative to DT `pix_clk_hz`,
  settle timing, or receiver expectations.

### Why it is not the strongest remaining hypothesis

However, as of now it is not the strongest remaining single explanation for the
observed *complete* lack of receiver ingress:

- official NVIDIA route-C examples on this platform use `24000`, not `25000`;
- route-A branches that explicitly used `24000` also still produced the same
  `no receiver ingress` signature;
- both blind cross-route hybrids reproduced the same signature as well;
- receiver-side clocks come up, but trace still shows:
  - no `SOF`
  - no `EOF`
  - no `rtcpu_nvcsi_intr`
  - no `vi_frame_begin/end`

So `24 vs 25 MHz` remains a bounded secondary hypothesis, not the dominant one.

## Practical Conclusion

The focused audit supports this working ranking:

1. strongest blocker:
   - physical CSI path or carrier-specific electrical routing mismatch
2. secondary software/electrical hypothesis:
   - route-C DT timing intent still assumes `25 MHz` while runtime delivers
     `24 MHz`
3. weaker hypothesis:
   - simple media-graph shape mistake

## Next Best Software-Only Follow-Up

If we continue software-only, the most coherent next bounded experiment is:

- align canonical route-C DT from `mclk_khz = 25000` to `24000`
- recompute the dependent mode-side intent fields conservatively
- retest on the canonical route-C baseline only

That would close the remaining `25 MHz intent vs 24 MHz runtime` gap cleanly.
