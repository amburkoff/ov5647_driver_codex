# 2026-04-22 Route-C Continuous Clock Post-Reboot

## Summary

The route-C continuous-clock dev boot completed. The live device tree now matches the staged receiver-side continuous-clock experiment.

No driver load, unload, capture, stream, or reboot was run by Codex after reconnect.

## Verified State

- active boot profile: `boot_profile=ov5647-dev`;
- active dev overlay: `/boot/ov5647-p3768-port-c-contclk.dtbo`;
- safe boot profile still present in `/boot/extlinux/extlinux.conf`;
- dev boot default remains `DEFAULT ov5647-dev`;
- live route-C sensor node: `/sys/firmware/devicetree/base/bus@0/cam_i2cmux/i2c@1/ov5647_c@36`;
- live `mode0/discontinuous_clk`: `no`;
- `nv_ov5647` is not loaded;
- `/dev/video0` is absent before manual LKM load;
- `/dev/media0` is present.

## Pstore

`/sys/fs/pstore/console-ramoops-0` exists after this boot. The captured head starts with the current kernel boot log and includes the current `boot_profile=ov5647-dev` command line.

Current interpretation: this is recorded as pstore evidence to preserve, but it is not treated as proof of a new kernel panic unless a later full-file inspection finds explicit panic/oops markers.

## Logs And Artifacts

- `logs/20260422T083900Z-cmdline-after-contclk-reboot.log`
- `logs/20260422T083900Z-live-dt-discontinuous-after-contclk-reboot.log`
- `logs/20260422T083900Z-basic-state-after-contclk-reboot.log`
- `logs/20260422T084327Z-collect_post_reboot.log`
- `logs/20260422T084330Z-collect-post-reboot-contclk-sudo.log`
- `logs/20260422T084330Z-live-dt-ov5647-c-after-contclk-reboot.hex.log`
- `logs/20260422T084330Z-pstore-after-contclk-reboot.log`
- `logs/20260422T084445Z-post-reboot-quick-state.log`
- `artifacts/post-reboot/20260422T084327Z/`

## Next Manual Test

Run the risky runtime steps manually to preserve Codex CLI context if the Jetson hangs.

```bash
sudo /home/cam/ov5647_driver_codex/scripts/run_manual_insmod_diag.sh full-delay-dump-contclk
```

If that returns cleanly and `/dev/video0` appears:

```bash
sudo /home/cam/ov5647_driver_codex/scripts/run_manual_single_frame_trace.sh
```

No reboot is needed for this next test.
