# 2026-04-22 Route-C Continuous Clock DT Prep

## Summary

A route-C DT overlay experiment was prepared to align the Jetson receiver DT clock-mode expectation with the OV5647 upstream-default continuous-clock stream-on path.

No reboot was requested or performed by Codex.

## Rationale

The previous runtime test changed only the sensor-side stream register:

- sensor `0x4800 = 0x04`;
- live DT still had `discontinuous_clk = "yes"`;
- capture still timed out.

That test did not validate a matched continuous-clock pair because NVCSI/VI still saw the DT as discontinuous-clock mode.

NVIDIA p3768 references are mixed:

- `imx219-C`: `discontinuous_clk = "yes"`;
- `imx477-C`: `discontinuous_clk = "no"`.

Upstream Linux OV5647 uses continuous clock by default unless non-continuous mode is explicitly requested. Therefore the next controlled reboot experiment should test:

- route C;
- OV5647 DT `discontinuous_clk = "no"`;
- driver loaded with `continuous_mipi_clock=1`.

## Source Change

Changed file:

- `patches/ov5647-p3768-port-c-probe.dts`

Change:

```text
discontinuous_clk = "no";
```

No other route-C fields were changed.

## Build

Command:

```bash
./scripts/build_overlay.sh patches/ov5647-p3768-port-c-probe.dts
```

Result:

- build passed with the existing graph/unit-address warnings;
- artifact: `artifacts/dtbo/20260422T082931Z-ov5647-p3768-port-c-probe.dtbo`;
- decompiled artifact confirms:
  - `tegra_sinterface = "serial_c"`;
  - `lane_polarity = "0"`;
  - `discontinuous_clk = "no"`;
  - `port-index = <2>`;
  - `bus-width = <2>`.

## Staging

The new DTBO was staged as a separate boot file:

- `/boot/ov5647-p3768-port-c-contclk.dtbo`

The current live boot config was not modified:

- current `/boot/extlinux/extlinux.conf` still points dev profile at `/boot/ov5647-p3768-port-c-probe.dtbo`;
- safe profile remains present.

SHA256:

- artifact and staged contclk DTBO: `690202ab9028771a933d134c3412b3a09c55777ae49bd15d249b04d238780c6b`;
- current live route-C probe DTBO: `85eed7f0b43e4ac7226759075b881e636efd898351c54fdf96f5913a768921d0`.

## Rendered Boot Candidate

Rendered only, not applied:

- `artifacts/boot/20260422T082942Z/extlinux.conf.generated`

This candidate uses:

- default profile: `ov5647-dev`;
- dev overlay: `/boot/ov5647-p3768-port-c-contclk.dtbo`;
- safe profile retained.

## Logs

- `logs/20260422T082820Z-route-c-overlay-source.log`
- `logs/20260422T082820Z-v4l2-all-after-contclk-timeout.log`
- `logs/20260422T082820Z-v4l2-formats-after-contclk-timeout.log`
- `logs/20260422T082820Z-media-after-contclk-timeout.log`
- `logs/20260422T082900Z-boot-dt-files.log`
- `logs/20260422T082900Z-extlinux-current-before-dt-contclk-prep.log`
- `logs/20260422T083045Z-imx219-c-overlay-fields.log`
- `logs/20260422T083045Z-imx477-c-overlay-fields.log`
- `logs/20260422T083120Z-current-ov5647-discontinuous-fields.log`
- `logs/20260422T083120Z-reference-discontinuous-summary.log`
- `logs/20260422T083155Z-build-route-c-contclk-overlay.log`
- `logs/20260422T083205Z-built-route-c-contclk-overlay-fields.log`
- `logs/20260422T083205Z-render-boot-route-c-contclk.log`
- `logs/20260422T083205Z-diff-route-c-contclk-overlay.log`
- `logs/20260422T083230Z-stage-route-c-contclk-overlay.log`

## Next Step

If this DT experiment is accepted, apply the rendered boot config with dev default and ask the user to run exactly:

```bash
sudo reboot
```

After reboot, validate `/proc/cmdline`, live DT `discontinuous_clk`, and run manual LKM/capture with:

```bash
sudo /home/cam/ov5647_driver_codex/scripts/run_manual_insmod_diag.sh full-delay-dump-contclk
sudo /home/cam/ov5647_driver_codex/scripts/run_manual_single_frame_trace.sh
```
