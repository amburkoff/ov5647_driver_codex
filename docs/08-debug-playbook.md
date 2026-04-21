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
