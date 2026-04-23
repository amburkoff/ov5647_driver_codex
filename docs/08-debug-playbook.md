# Debug Playbook

Safe order of operations:

1. Collect environment and kernel logs.
2. Build the module.
3. Load it manually.
4. Inspect `dmesg` immediately.
5. Unload it manually.
6. Re-check `dmesg` and `journalctl -k -b`.

Before changing DT or boot files:

- snapshot `/boot/extlinux/extlinux.conf`;
- generate the candidate config under `artifacts/boot/`;
- do not apply a dev entry that enables OV5647 until manual probe is stable.

When a probe attempt fails:

- save the full kernel log;
- save the exact module and overlay versions used;
- write one short root-cause hypothesis in `reports/`;
- change only one variable before the next run.

When a reboot is needed:

- preselect the intended default profile first;
- keep the safe profile available;
- after reconnect, read `/proc/cmdline` before anything else.

## Read-Only Route Snapshot

Use this when Codex context may be lost or before any risky module/capture command:

```bash
/home/cam/ov5647_driver_codex/scripts/collect_camera_route_state.sh
```

This helper is intentionally read-only. It does not load/unload modules, start streaming, or reboot. It saves cmdline, extlinux, I2C bus list, module state, media graph, and live OV5647 DT route fields under `artifacts/camera-route-state/<timestamp>/`.

## Manual Unload Hang Capture

Use manual-only unload tests. Do not run these from Codex when a hard hang is plausible.

Manual diagnostic load profiles:

```bash
sudo /home/cam/ov5647_driver_codex/scripts/run_manual_insmod_diag.sh full-delay
```

```bash
sudo /home/cam/ov5647_driver_codex/scripts/run_manual_insmod_diag.sh skip-register
```

```bash
sudo /home/cam/ov5647_driver_codex/scripts/run_manual_insmod_diag.sh skip-unregister
```

```bash
sudo /home/cam/ov5647_driver_codex/scripts/run_manual_insmod_diag.sh split-unregister
```

Use `split-unregister` only after a clean load of the rebuilt module. It replaces the single `tegracam_v4l2subdev_unregister()` call with marked sub-steps:

- `v4l2_ctrl_handler_free`;
- `v4l2_async_unregister_subdev`;
- `media_entity_cleanup`.

Basic trace:

```bash
sudo /home/cam/ov5647_driver_codex/scripts/run_manual_rmmod_trace.sh
```

The helper records `rmmod` stderr and exit code even when `rmmod` fails without unloading the module.

Trace with delayed SysRq task dumps:

```bash
sudo env RMMOD_SYSRQ_DELAY_SEC=10 /home/cam/ov5647_driver_codex/scripts/run_manual_rmmod_trace.sh
```

The SysRq mode is useful only if the kernel remains alive after `rmmod` stalls. If the Jetson hard-locks immediately, no watchdog output may be written.

## Manual Single-Frame Capture

Use this only after query-only V4L2 checks pass:

```bash
sudo /home/cam/ov5647_driver_codex/scripts/run_manual_single_frame_trace.sh
```

The helper records live dmesg, `v4l2-ctl` stderr/stdout, return code, raw file size, and a post-capture dmesg tail. It uses `CAPTURE_TIMEOUT_SEC=30` by default for userspace stalls; a hard kernel lock may still require manual reboot.

RTCPU/NVCSI traced capture for STREAMON timeouts:

```bash
sudo /home/cam/ov5647_driver_codex/scripts/run_manual_single_frame_rtcpu_trace.sh
```

This enables selected `camera_common`, `tegra_capture`, and `tegra_rtcpu` tracepoints only for the duration of one capture attempt and saves trace artifacts under `artifacts/traces/<timestamp>/`.

## Receiver-Side Safety Note

Do not casually read vendor `debugfs regset32` files under camera-related
`debugfs` paths on this image.

Pstore now contains a kernel panic showing:

- `debugfs_print_regs32()`
- `debugfs_show_regset32()`
- userspace `cat`

The current safe bias is:

- prefer RTCPU tracepoints and source inspection first;
- avoid direct reads of `VI/NVCSI/camrtc` register-dump files until a safe node
  subset is identified from source.

## Safe Hook Inventory

Use this helper to collect the current receiver-side hook map from safe sources
only:

```bash
/home/cam/ov5647_driver_codex/scripts/collect_nvcsi_vi_hooks.sh
```

It collects:

- loaded camera/receiver modules;
- official local header definitions for `camrtc` trace IDs;
- sparse-checked-out `linux-nv-oot-r36.5` source paths for `nvcsi`, `vi`, and `rtcpu`;
- source-created debugfs node names from `rtcpu-debug.c` and `vi5.c`;
- the tracepoint list used by `run_manual_single_frame_rtcpu_trace.sh`.

It does **not** read live vendor `debugfs regset32` files.
