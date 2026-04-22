# Clock ID Root Cause - 2026-04-22

## Summary

The route-C MCLK diagnostic test did not produce a frame, but it exposed a real DT clock binding bug. The overlay named the sensor clock `extperiph1`, but the phandle used BPMP clock ID `0x07`, which is `TEGRA234_CLK_AUD_MCLK`, not `TEGRA234_CLK_EXTPERIPH1`.

## Evidence

- Manual `insmod full-delay-dump-contclk-mclk24` returned `rc=0`.
- Manual RTCPU/NVCSI capture returned `rc=124`.
- Raw output remained zero bytes.
- RTCPU/NVCSI trace still had no SOF, EOF, NVCSI interrupt, or vinotify error.
- Driver MCLK logs showed:
  - requested `mclk_override_hz=24000000`;
  - effective enabled rate `22579199 Hz`;
  - this matches audio-MCLK behavior, not an exact 24 MHz camera MCLK.
- Header check:
  - `TEGRA234_CLK_AUD_MCLK = 7`;
  - `TEGRA234_CLK_EXTPERIPH1 = 36`.
- Live DT before reboot still contains `clocks = <&bpmp 0x07>`.

## Changes

- Updated `patches/ov5647-p3768-port-c-probe.dts` to use `clocks = <&bpmp 0x24>`.
- Updated `patches/ov5647-p3768-port-a-probe.dts` to use the same corrected clock ID.
- Built `artifacts/dtbo/20260422T134331Z-ov5647-p3768-port-c-probe.dtbo`.
- Staged `/boot/ov5647-p3768-port-c-extperiph1.dtbo`.
- Updated `/boot/extlinux/extlinux.conf`:
  - `DEFAULT ov5647-dev`;
  - dev entry uses `OVERLAYS /boot/ov5647-p3768-port-c-extperiph1.dtbo`;
  - safe entry remains present.

## Logs

- `logs/20260422T134153Z-analyze-manual-mclk24-rtcpu-result.log`
- `logs/20260422T134218Z-inspect-active-clock-tree-after-mclk24-capture.log`
- `logs/20260422T134246Z-find-tegra234-bpmp-clock-ids.log`
- `logs/20260422T134246Z-inspect-live-ov5647-clock-phandle-id.log`
- `logs/20260422T134331Z-build_overlay-ov5647-p3768-port-c-probe.log`
- `logs/20260422T134339Z-stage-route-c-extperiph1-overlay-and-dev-boot.log`
- `logs/20260422T134349Z-verify-staged-extperiph1-dtbo.log`

## Next Step

Reboot is required to apply the corrected DT overlay. After reboot:

1. Confirm `/proc/cmdline` contains `boot_profile=ov5647-dev`.
2. Confirm live DT `clocks` for `ov5647_c@36` is `0x24`.
3. Manually load the module with `full-delay-dump-contclk-mclk24`.
4. Verify MCLK logs show an effective 24 MHz route before running another traced capture.

No runtime load/unload/capture/reboot command was run by Codex after staging the boot profile.
