# 2026-04-21 Handoff Summary

## Goal

Develop and validate a reproducible OV5647 MIPI CSI-2 camera driver bring-up for Jetson Orin NX on L4T R36.5 / JetPack 6.2.2, using the CBL Developer Kit as a carrier-specific target.

The practical first milestone remains:

- one OV5647 sensor;
- one confirmed CSI route;
- 2-lane configuration;
- one minimal stable mode;
- stable manual module lifecycle;
- non-empty raw capture and visible preview.

## Current State

- Active boot profile:
  - `boot_profile=ov5647-dev`
- Latest pushed commit:
  - `bd681fc debug: instrument ov5647 module exit and log fourth rmmod hang`
- Current module state at handoff snapshot:
  - `nv_ov5647` is loaded;
  - the user reported the latest manual `insmod` as `ok`.
- Handoff snapshot:
  - `logs/20260421T084235Z-handoff-snapshot.log`

## What Is Done

- Repository scaffold exists with `docs/`, `reports/`, `logs/`, `artifacts/`, `scripts/`, `src/`, `patches/`, and `tools/`.
- Safe/dev boot profile workflow exists and the current boot identifies itself through `boot_profile=ov5647-dev`.
- Route-A probe overlay applies at boot on this system and creates the live OV5647 DT node.
- Confirmed live bring-up path so far:
  - `tegra_sinterface = "serial_b"`;
  - `port-index = 1`;
  - `bus-width = <2>`;
  - `lane_polarity = "6"`;
  - muxed I2C bus `i2c-9`;
  - sensor address `0x36`;
  - chip ID `0x5647`;
  - `pwdn_gpio = 397` must remain high for the current path.
- Driver probe reaches successful chip-ID read and subdev registration.
- Kernel creates `/dev/video0`, `/dev/v4l-subdev0`, `/dev/v4l-subdev1`, and `/dev/media0`.
- `v4l2-compliance -d /dev/video0` previously passed.
- First stream path now reaches `ov5647_start_streaming()` and returns without immediate kernel crash.
- A prior NULL-dereference panic in `ov5647_remove -> ov5647_power_off` was fixed by guarding invalid state and hardening remove/power-off.
- Current unload debugging has explicit instrumentation around:
  - `module_exit`;
  - `i2c_del_driver`;
  - `ov5647_remove`;
  - `tegracam_v4l2subdev_unregister`;
  - `tegracam_device_unregister`.

## Important Changed Files

- `src/nv_ov5647/nv_ov5647.c`
  - OV5647 tegracam scaffold;
  - DT parse, regulator/clock/GPIO handling;
  - chip-ID probe;
  - minimal mode table and streaming hooks;
  - unload and module-exit instrumentation.
- `scripts/run_manual_rmmod_trace.sh`
  - manual-only unload helper with live dmesg capture and pre-rmmod state snapshot.
- `scripts/run_manual_single_frame_trace.sh`
  - manual-only single-frame capture helper with live dmesg capture.
- `scripts/build_module.sh`
  - external module build pipeline.
- `docs/10-results-and-status.md`
  - current project state and blockers.
- `docs/11-known-issues.md`
  - unresolved hardware, unload, and stream/capture risks.
- `reports/2026-04-20-fourth-reboot-rmmod-hang.md`
  - latest preserved unload-hang analysis.

## Remaining Work

- Stabilize `rmmod` before doing repeated streaming work.
- Use the new `module_exit/i2c_del_driver` markers to locate the exact unload hang boundary.
- Fix the underlying unload hang once the boundary is known.
- Continue mode/CSI timing work because current capture reaches STREAMON but VI times out.
- Produce a non-empty raw frame and validate file size/statistics/Bayer plausibility.
- Build a stable preview path only after raw capture is real and repeatable.
- Complete CBL carrier-specific physical mapping documentation beyond the live DT route.
- Clean up or intentionally commit remaining untracked artifacts from previous build/capture/log runs.

## Current Risks

- `sudo rmmod nv_ov5647` can still hard-hang the Jetson.
- The next unload test is intentionally risky and must remain manual-only.
- `pstore` has not always preserved useful data after unload hangs.
- Stream-on currently does not deliver frames to VI:
  - prior raw output was zero bytes;
  - kernel logged `uncorr_err: request timed out after 2500 ms`.
- Physical connector mapping on the CBL Developer Kit is still not independently verified.
- Two identical Raspberry Pi-market OV5647 cameras are connected, so the live route is validated electrically/logically but not yet mapped confidently to a physical connector label.

## Next Best Step

Run exactly one manual unload helper invocation while preserving the Codex session. This should reveal whether the last visible marker is before `i2c_del_driver`, inside `ov5647_remove`, or after one of the tegracam unregister calls.

Manual command:

```bash
sudo /home/cam/ov5647_driver_codex/scripts/run_manual_rmmod_trace.sh
```

Expected user response:

- `rmmod ok` if the command returns;
- `hang` if the Jetson freezes;
- `rebooted` after manual reboot if a hang occurred.

Do not run additional `insmod`, `rmmod`, `STREAMON`, or capture commands until the result of this one unload test is recorded.
