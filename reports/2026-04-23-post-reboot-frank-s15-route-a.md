# Post-Reboot Route-A State With Frank-s15-v1.0 Camera

Date: 2026-04-23

## What Changed Physically

After reboot, the user replaced the previous camera on Jetson `cam0` with another OV5647 and a longer ribbon marked `Frank-s15-v1.0`.

This changes one physical variable while keeping the current software setup the same:

- boot profile remains `ov5647-dev`;
- live DT remains route A;
- driver build remains the `0x3821 = 0x03` diagnostic variant.

## Post-Reboot State

- `/proc/cmdline` still contains `boot_profile=ov5647-dev`.
- Live DT still exposes:
  - `cam_i2cmux/i2c@0/ov5647_a@36`;
  - `tegra_sinterface = "serial_b"`;
  - endpoint `port-index = 1`;
  - `lane_polarity = 6`;
  - `clocks = <&bpmp 0x24>`.
- `nv_ov5647` is not loaded after reboot.
- `/dev/video0` is absent before manual `insmod`.
- `media-ctl -p` shows only the base `nvcsi` entity before sensor module load.
- `pstore` is empty after reboot.

## Manual Command Result

The user ran `run_manual_rmmod_trace.sh` three times.

Each time:

- `rmmod` returned `rc=1`;
- error text was `Module nv_ov5647 is not currently loaded`.

This is expected because the system rebooted and the driver is not configured for boot-time auto-load.

## Next Step

Do not run `rmmod` again.

Next manual commands:

```bash
sudo /home/cam/ov5647_driver_codex/scripts/run_manual_insmod_diag.sh full-delay-dump-contclk-mclk24
sudo /home/cam/ov5647_driver_codex/scripts/run_manual_single_frame_rtcpu_trace.sh
```

Run the second command only if the first one reports `insmod rc=0`.
