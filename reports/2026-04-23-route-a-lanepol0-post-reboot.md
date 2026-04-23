# Route-A Lane-Polarity-0 Post-Reboot

Date: 2026-04-23

## Boot Result

- Reboot completed successfully.
- `/proc/cmdline` contains `boot_profile=ov5647-dev`.
- `pstore` is empty after this reboot.
- `nv_ov5647` is not loaded automatically.
- `/dev/video0` is absent before manual module load.

## Live DT Confirmation

The staged overlay is active in the running device tree:

- node: `cam_i2cmux/i2c@0/ov5647_a@36`
- `tegra_sinterface = "serial_b"`
- `port-index = 1`
- `bus-width = 2`
- `lane_polarity = 0`
- `discontinuous_clk = "yes"`
- `clocks = <&bpmp 0x24>` / `extperiph1`

This confirms the reboot applied the intended one-variable DT change.

## Next Manual Runtime Test

Because the module is not loaded after reboot, skip `rmmod` and run only:

```bash
sudo /home/cam/ov5647_driver_codex/scripts/run_manual_insmod_diag.sh full-delay-dump-mclk24
sudo /home/cam/ov5647_driver_codex/scripts/run_manual_single_frame_rtcpu_trace.sh
```

Run the capture only if the `insmod` command reports `insmod rc=0`.
