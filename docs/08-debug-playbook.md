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

## Canonical Route-C Baseline Check

Use this after staging `ov5647-dev` back to the canonical route-C reference
overlay and again after the next reboot:

```bash
/home/cam/ov5647_driver_codex/scripts/collect_reference_baseline_state.sh
```

This helper is also read-only. It saves a compact baseline package under:

- `artifacts/reference-baseline-state/<timestamp>/`

and emits explicit assertions for:

- `boot_profile=ov5647-dev`
- on-disk `extlinux` overlay path
- expected live DT node `cam_i2cmux/i2c@1/ov5647_c@36`
- expected route-C mode fields:
  - `serial_c`
  - `lane_polarity=0`
  - `num_lanes=2`
  - `discontinuous_clk=yes`
  - `cil_settletime=0`

This is useful immediately after staging the boot config, because it will show
the honest mixed state:

- `PASS` for the new on-disk `extlinux` overlay
- `FAIL` for the live DT node until the user performs the next reboot

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

## RTCPU Trace Analysis

After a manual traced capture, summarize the result with:

```bash
/home/cam/ov5647_driver_codex/scripts/analyze_rtcpu_trace.sh \
  /home/cam/ov5647_driver_codex/artifacts/traces/<timestamp>
```

This helper parses `final-trace.log` or `after-trace.log` and reports counts
for the most important receiver-side events:

- `capture_event_sof/eof/error/wdt`
- `rtcpu_nvcsi_intr`
- `rtcpu_vinotify_error`
- `vi_frame_begin/end`
- `capture_ivc_send/recv`
- `vi_task_submit`

It also emits a compact diagnosis such as:

- `receiver_signature=no_receiver_ingress_visible`
- `receiver_signature=receiver_sees_errors_without_frame`
- `receiver_signature=receiver_activity_present`

## Clock And PM Snapshot

To collect a standalone read-only Jetson clock/power-domain snapshot:

```bash
sudo /home/cam/ov5647_driver_codex/scripts/collect_clk_pm_state.sh
```

This saves:

- `clk/extperiph1`
- `clk/nvcsi`
- `clk/nvcsilp`
- `clk/vi`
- `pm_genpd/vi`
- `pm_genpd/ispa`

The traced capture helper already runs this automatically and saves:

- `artifacts/traces/<timestamp>/clk-pm-before`
- `artifacts/traces/<timestamp>/clk-pm-after`

It now also performs timed sampling during the capture timeout window and saves:

- `artifacts/traces/<timestamp>/clk-pm-samples/sample-0000`
- `artifacts/traces/<timestamp>/clk-pm-samples/sample-0001`
- ...

Sampling interval defaults to:

- `CLK_PM_SAMPLE_INTERVAL_SEC=1`

Use this to compare Jetson-side clock and power-domain state across
`no SOF` runs without touching risky `VI/camrtc` register-dump nodes.

## Manual Safe RTCPU Debugfs Dump

After a reboot or after a traced capture, if you want one small receiver-side
readout without touching known-dangerous register dump nodes, use:

```bash
sudo /home/cam/ov5647_driver_codex/scripts/run_manual_safe_rtcpu_debugfs_dump.sh
```

This helper is intentionally limited to:

- `/sys/kernel/debug/tegra_rtcpu_trace/stats`
- `/sys/kernel/debug/tegra_rtcpu_trace/last_exception`
- `/sys/kernel/debug/tegra_rtcpu_trace/last_event`

These files were chosen from official `linux-nv-oot-r36.5` source because
`tegra-rtcpu-trace.c` creates them with `debugfs_create_file()` and
`single_open()`/`seq_read()` handlers, not with `debugfs_create_regset32()`.

It does **not** read:

- `VI` `debugfs_create_regset32("ch0", ...)`
- `camrtc` `regs-common`
- `camrtc` `regs-region*`

Current practical whitelist:

- `tegra_rtcpu_trace/stats`
- `tegra_rtcpu_trace/last_exception`
- `tegra_rtcpu_trace/last_event`

Current practical blacklist:

- `vi/.../ch0`
- `camrtc/ast-cpu/regs-common`
- `camrtc/ast-cpu/regs-region*`
- `camrtc/ast-dma/regs-common`
- `camrtc/ast-dma/regs-region*`

Reason for the blacklist:

- pstore already captured a kernel panic in `debugfs_print_regs32()` from a
  userspace `cat`;
- `vi5.c` and `rtcpu-debug.c` both create camera-path register dumps through
  `debugfs_create_regset32()`;
- these nodes are therefore unsafe to probe casually on the live target.

Current live-layout caveat:

- on this target runtime there is no exported `camrtc/` debugfs root;
- `vi0/vi1` currently expose only `ch0`, which is a `debugfs_create_regset32()`
  node and remains blacklisted;
- `nvcsi` is present as a directory, but no low-risk child files are currently
  visible in the exported layout.
