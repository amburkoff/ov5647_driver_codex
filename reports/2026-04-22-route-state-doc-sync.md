# Route State Documentation Sync

Date: 2026-04-22

## What Changed

- Corrected carrier naming in Markdown to `CLB Developer Kit`.
- Recorded new user-reported physical facts: the box says partner `makerobo`, and the bundled booklet says to install the official Jetson Developer Kit image.
- Updated CLB carrier mapping documentation to reflect the current live route-C continuous-clock state instead of stale route-A wording.
- Updated DT overlay design documentation to mark route-C as the active dev overlay and to record the no-SOF conclusion.
- Added the official NVIDIA Jetson Orin Nano Developer Kit carrier board specification as a reference-only source for p3768-style connector routing.
- Added `scripts/collect_camera_route_state.sh`, a read-only route snapshot helper.
- Documented the helper in the debug playbook and README.

## Commands Run

- `bash -n scripts/collect_camera_route_state.sh`
- `/home/cam/ov5647_driver_codex/scripts/collect_camera_route_state.sh`
- `git diff`

All command output was saved under `logs/`.

## Evidence

- Latest read-only route snapshot: `artifacts/camera-route-state/20260422T132108Z/`
- Active boot profile: `boot_profile=ov5647-dev`
- Module state during snapshot: `nv_ov5647 not loaded`
- Live route-C facts:
  - active node: `cam_i2cmux/i2c@1/ov5647_c@36`
  - `status = "okay"`
  - `tegra_sinterface = "serial_c"`
  - endpoint `port-index = <2>`
  - endpoint `bus-width = <2>`
  - `lane_polarity = "0"`
  - `discontinuous_clk = "no"`
- Disabled route-A placeholder remains in live DT:
  - `cam_i2cmux/i2c@0/ov5647_a@36`
  - `status = "disabled"`

## Result

No risky command was run. No module load, unload, capture, stream, poweroff, or reboot was performed from Codex.

The repo now has a reproducible read-only state capture path that can be run before any risky manual test.

## Current Hypothesis

The latest RTCPU/NVCSI evidence shows no SOF and no receiver-side error event. With route A and route C both timing out, the next highest-value work is physical CSI path validation: CLB/makerobo connector mapping, cable/adapter pinout, lane polarity only if justified, or a known-good Jetson camera cross-check.

## Next Smallest Step

Do not run another blind stream-register or DT variant. First collect or verify physical evidence for the CLB connector/cable path, or test a known-good Jetson-compatible camera on the same connector.
