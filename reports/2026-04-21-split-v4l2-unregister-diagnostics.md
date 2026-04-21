# 2026-04-21 Split V4L2 Unregister Diagnostics

## Context

- full V4L2-registration unload remains the highest-risk operation;
- the currently loaded module is older than the rebuilt source and must not be unloaded from Codex;
- the next useful change is better crash localization before any manual unload retest.

## Change Prepared

- added diagnostic module parameter:
  - `split_v4l2_unregister=1`
- when enabled, `ov5647_remove()` does not call `tegracam_v4l2subdev_unregister()` directly;
- instead, it performs equivalent marked phases:
  - `v4l2_ctrl_handler_free`;
  - `v4l2_async_unregister_subdev`;
  - `media_entity_cleanup`.

## Build / Static Validation

- build passed:
  - `logs/20260421T094354Z-build_module-split-unregister-is-enabled.log`
- `modinfo` shows the new parameter and dependency on `v4l2-async`:
  - `logs/20260421T094407Z-modinfo-split-unregister-is-enabled.log`
- undefined-symbol check confirms the diagnostic path links against:
  - `v4l2_ctrl_handler_free`;
  - `v4l2_async_unregister_subdev`.
  - `logs/20260421T094407Z-nm-undefined-split-unregister-is-enabled.log`
- diff whitespace check passed:
  - `logs/20260421T094407Z-git-diff-check-split-unregister-is-enabled.log`

## Important Detail

The first implementation used `defined(CONFIG_V4L2_ASYNC)`, but this target exposes `CONFIG_V4L2_ASYNC_MODULE=1`. The diagnostic was corrected to use `IS_ENABLED(CONFIG_V4L2_ASYNC)` so the async unregister marker is actually compiled into the external module.

Kernel config evidence:

- `logs/20260421T094330Z-kernel-config-v4l2-async-media.log`

## Runtime Status

- not runtime-tested;
- no `rmmod`, `insmod`, capture, stream, or reboot was run for this checkpoint.

## Next Manual Test, When Safe

Only after the current old module is no longer loaded, use:

```bash
sudo /home/cam/ov5647_driver_codex/scripts/run_manual_insmod_diag.sh split-unregister
```

Then, if load succeeds, run exactly one unload trace manually:

```bash
sudo /home/cam/ov5647_driver_codex/scripts/run_manual_rmmod_trace.sh
```
