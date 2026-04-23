# Safe RTCPU Debugfs Whitelist

Date: 2026-04-23

## Goal

Define a receiver-side debugfs subset that is safer than the vendor register
dump nodes already implicated in a kernel panic on this image.

## Source Basis

Official NVIDIA `linux-nv-oot-r36.5` source was inspected in:

- `tools/vendor/linux-nv-oot-r36.5/drivers/platform/tegra/rtcpu/tegra-rtcpu-trace.c`
- `tools/vendor/linux-nv-oot-r36.5/drivers/platform/tegra/rtcpu/rtcpu-debug.c`
- `tools/vendor/linux-nv-oot-r36.5/drivers/video/tegra/host/vi/vi5.c`

Saved source-audit artifacts:

- `logs/20260423T150700Z-nvcsi-vi-debugfs-source-audit.log`
- `logs/20260423T150700Z-rtcpu-trace-debugfs-window.log`
- `logs/20260423T150700Z-camrtc-debugfs-window.log`
- `logs/20260423T150700Z-vi5-debugfs-window.log`

## Whitelist

The current whitelist is:

- `/sys/kernel/debug/tegra_rtcpu_trace/stats`
- `/sys/kernel/debug/tegra_rtcpu_trace/last_exception`
- `/sys/kernel/debug/tegra_rtcpu_trace/last_event`

Reason:

- `tegra-rtcpu-trace.c` creates these nodes with `debugfs_create_file()`;
- their file operations are built via `DEFINE_SEQ_FOPS(...)`;
- that path resolves to `single_open()` plus `seq_read()`;
- it does not go through `debugfs_create_regset32()`.

This does **not** prove they are runtime-safe in every state, but they are a
better next candidate than the known-dangerous register-dump files.

## Blacklist

The current blacklist is:

- `vi/.../ch0`
- `camrtc/ast-cpu/regs-common`
- `camrtc/ast-cpu/regs-region*`
- `camrtc/ast-dma/regs-common`
- `camrtc/ast-dma/regs-region*`

Reason:

- `vi5.c` creates `ch0` via `debugfs_create_regset32("ch0", ...)`;
- `rtcpu-debug.c` creates AST register dump files via
  `debugfs_create_regset32("regs-common", ...)` and
  `debugfs_create_regset32("regs-region*", ...)`;
- pstore already captured a kernel panic in `debugfs_print_regs32()` from a
  userspace `cat`, which matches this register-dump class of debugfs node.

## Practical Outcome

The repository now carries a manual helper for the whitelist only:

- `scripts/run_manual_safe_rtcpu_debugfs_dump.sh`

It collects:

- `/proc/cmdline`
- camera-related `lsmod` snapshot
- `tegra_rtcpu_trace/stats`
- `tegra_rtcpu_trace/last_exception`
- `tegra_rtcpu_trace/last_event`

It intentionally avoids `VI/camrtc` regset nodes.

## Next Safe Manual Step

After the next manual traced capture, the best low-risk receiver-side follow-up
is:

```bash
sudo /home/cam/ov5647_driver_codex/scripts/run_manual_safe_rtcpu_debugfs_dump.sh
```

This should be treated as a manual-only experiment, not an automatic step,
because it still touches live camera debugfs state.
