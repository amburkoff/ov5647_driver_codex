# Live Receiver Debugfs Layout

Date: 2026-04-23

## Goal

Check which receiver-side camera debugfs nodes are actually present on the live
target after the RTCPU whitelist work, without reading risky camera register
dump files.

## Commands Run

```bash
sudo find /sys/kernel/debug -maxdepth 3 -type d
sudo find /sys/kernel/debug/vi0 /sys/kernel/debug/vi1 /sys/kernel/debug/nvcsi -maxdepth 2 \( -type d -o -type f \)
```

## Saved Logs

- `logs/20260423T152409Z-debugfs-dir-scan-sudo.log`
- `logs/20260423T152545Z-vi-nvcsi-debugfs-layout.log`

## Result

Live receiver-relevant directories currently visible are:

- `/sys/kernel/debug/vi0`
- `/sys/kernel/debug/vi1`
- `/sys/kernel/debug/nvcsi`
- `/sys/kernel/debug/tegra_rtcpu_trace`

Observed receiver-side file layout:

- `/sys/kernel/debug/vi0/ch0`
- `/sys/kernel/debug/vi1/ch0`
- `/sys/kernel/debug/nvcsi` (directory only, no visible child files at depth 2)
- `/sys/kernel/debug/tegra_rtcpu_trace/{stats,last_exception,last_event}`

Notably absent:

- no live `camrtc/` debugfs root was found;
- no live `version`, `irqstat`, or `memstat` camera-RTCPU files were found.

## Interpretation

This matters because the earlier source audit showed:

- `camrtc/version`, `irqstat`, and `memstat` would have been possible
  non-regset candidates if their debugfs root existed live;
- but on this target/kernel runtime, that `camrtc` debugfs root is not
  currently exported;
- `vi0/ch0` and `vi1/ch0` are not usable as safe next reads because `vi5.c`
  creates them with `debugfs_create_regset32("ch0", ...)`, the same class of
  path already implicated in the recorded `debugfs_print_regs32()` panic.

## Practical Conclusion

For the current live runtime, the remaining safe-ish receiver-side debugfs path
is effectively limited to:

- `tegra_rtcpu_trace/stats`
- `tegra_rtcpu_trace/last_exception`
- `tegra_rtcpu_trace/last_event`

No additional low-risk live `camrtc` or `nvcsi` debugfs readout is currently
available from the exported debugfs layout.
