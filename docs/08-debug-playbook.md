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

