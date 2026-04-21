# 2026-04-21 Keep set_mode in Standby

## Context

- single-frame capture reached `VIDIOC_STREAMON`;
- raw output stayed zero bytes;
- VI reported repeated capture timeouts;
- kernel and cleanup path survived;
- current loaded module still contains the previous behavior until the next manual reload.

## Finding

NVIDIA r36.5 tegracam calls sensor `set_mode()` before `start_streaming()`.

Official/reference evidence:

- `tegracam_v4l2.c` calls `sensor_ops->set_mode(tc_dev)` before stream start operations;
- NVIDIA `nv_imx219.c` keeps `imx219_set_mode()` limited to common/mode table writes;
- NVIDIA `nv_imx219.c` starts sensor output separately via `imx219_start_streaming()`.

Reference grep:

- `logs/20260421T103017Z-set-mode-standby-reference-grep.log`

## Change Prepared

- removed the `OV5647_REG_MODE_SELECT = OV5647_MODE_STREAMING` write from `ov5647_set_mode()`;
- `ov5647_set_mode()` now writes common/mode registers and leaves the sensor in standby;
- `OV5647_REG_MODE_SELECT = OV5647_MODE_STREAMING` remains in `ov5647_start_streaming()`;
- this aligns OV5647 behavior with the Jetson r36.5 tegracam sequencing model.

## Validation

- module build passed:
  - `logs/20260421T103004Z-build_module-set-mode-standby.log`
- `modinfo` passed:
  - `logs/20260421T103017Z-modinfo-set-mode-standby.log`
- diff whitespace check passed:
  - `logs/20260421T103017Z-git-diff-check-set-mode-standby.log`

## Runtime Status

- not loaded yet;
- not capture-tested yet;
- current in-kernel module is still the previous build.

## Next Step

Runtime validation requires a safe manual reload or reboot into a clean module state. Do not test this by running `rmmod` from Codex.
