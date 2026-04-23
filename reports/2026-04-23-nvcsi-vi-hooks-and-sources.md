# NVCSI/VI Hooks And Sources

Date: 2026-04-23

## Goal

Identify what is available locally and officially for deeper receiver-side
instrumentation on Jetson Linux `r36.5`.

## Local Runtime Findings

Loaded/installed runtime modules on the target include:

- `/lib/modules/5.15.185-tegra/updates/drivers/video/tegra/host/nvcsi/nvhost-nvcsi.ko`
- `/lib/modules/5.15.185-tegra/updates/drivers/video/tegra/host/nvcsi/nvhost-nvcsi-t194.ko`
- `/lib/modules/5.15.185-tegra/updates/drivers/video/tegra/host/vi/nvhost-vi5.ko`
- `/lib/modules/5.15.185-tegra/updates/drivers/video/tegra/host/capture/nvhost-capture.ko`
- `/lib/modules/5.15.185-tegra/updates/drivers/platform/tegra/rtcpu/tegra-camera-rtcpu.ko`
- `/lib/modules/5.15.185-tegra/updates/drivers/platform/tegra/rtcpu/capture-ivc.ko`

Installed headers on the target include:

- `/usr/src/nvidia/nvidia-oot/include/uapi/linux/nvhost_nvcsi_ioctl.h`
- `/usr/src/nvidia/nvidia-oot/include/media/fusa-capture/capture-vi.h`
- `/usr/src/nvidia/nvidia-oot/include/media/mc_common.h`
- `/usr/src/nvidia/nvidia-oot/include/linux/tegra-camera-rtcpu.h`
- `/usr/src/nvidia/nvidia-oot/include/linux/tegra-rtcpu-trace.h`
- `/usr/src/nvidia/nvidia-oot/include/soc/tegra/camrtc-trace.h`

## Official r36.5 Source Retrieval

Official NVIDIA repository is reachable and exposes the expected release branch:

- repo: `https://gitlab.com/nvidia/nv-tegra/linux-nv-oot.git`
- branch: `refs/heads/l4t/l4t-r36.5`
- tag: `refs/tags/jetson_36.5`

To make the next debug step practical, a shallow sparse checkout was added under:

- `tools/vendor/linux-nv-oot-r36.5`

with these directories:

- `drivers/video/tegra/host/nvcsi`
- `drivers/video/tegra/host/vi`
- `drivers/platform/tegra/rtcpu`
- `drivers/media/platform/tegra/camera`

## Most Relevant Source Files

Receiver-side code:

- `tools/vendor/linux-nv-oot-r36.5/drivers/video/tegra/host/nvcsi/nvcsi.c`
- `tools/vendor/linux-nv-oot-r36.5/drivers/video/tegra/host/nvcsi/nvcsi-t194.c`
- `tools/vendor/linux-nv-oot-r36.5/drivers/video/tegra/host/vi/vi5.c`
- `tools/vendor/linux-nv-oot-r36.5/drivers/platform/tegra/rtcpu/tegra-camera-rtcpu-base.c`
- `tools/vendor/linux-nv-oot-r36.5/drivers/platform/tegra/rtcpu/tegra-rtcpu-trace.c`
- `tools/vendor/linux-nv-oot-r36.5/drivers/platform/tegra/rtcpu/rtcpu-debug.c`

## Useful Hooks Found

Trace/event definitions exist locally in NVIDIA headers:

- `camrtc_trace_vinotify_error`
- `camrtc_trace_vi_frame_begin`
- `camrtc_trace_nvcsi_intr`
- `camrtc_trace_capture_event_sof`
- `camrtc_trace_capture_event_eof`

These are defined in:

- `/usr/src/nvidia/nvidia-oot/include/soc/tegra/camrtc-trace.h`

Camera RTCPU helper APIs exist in:

- `/usr/src/nvidia/nvidia-oot/include/linux/tegra-camera-rtcpu.h`

including:

- `tegra_camrtc_flush_trace()`
- `tegra_camrtc_print_version()`
- `tegra_camrtc_reboot()`
- `tegra_camrtc_restore()`

`vi5` debugfs support exists in source:

- `drivers/video/tegra/host/vi/vi5.c`
- `vi5_init_debugfs()`
- `debugfs_create_regset32("ch0", ...)`

`camrtc` debugfs support exists in source:

- `drivers/platform/tegra/rtcpu/rtcpu-debug.c`

including debugfs files/directories for:

- `version`
- `reboot`
- `ping`
- `sm-ping`
- `log-level`
- `forced-reset-restore`
- `irqstat`
- `memstat`
- `coverage/vi`
- `coverage/isp`
- RTOS/test-related control files

## Important Runtime Hazard Found

After probing the debug path, the Jetson rebooted and pstore shows the reason:

- kernel NULL dereference in `debugfs_print_regs32()`
- call trace:
  - `debugfs_print_regs32`
  - `debugfs_show_regset32`
  - `seq_read_iter`
  - `seq_read`
  - `vfs_read`
  - `ksys_read`
- process name was `cat`

This strongly suggests that at least one vendor `debugfs regset32` node in the
camera path can panic the kernel when read on this image.

Practical consequence:

- do **not** read `VI/NVCSI/camrtc` debugfs regset files casually on the live target;
- prefer source inspection and existing RTCPU tracepoints first.

## Best Next Receiver-Side Step

The safest next step is now:

1. inspect the fetched `linux-nv-oot-r36.5` sources for the exact debugfs node
   names created by `vi5.c` and `rtcpu-debug.c`;
2. use only tracepoint-based collection first;
3. avoid direct reads of `debugfs regset32` nodes until a safe subset is
   identified.
