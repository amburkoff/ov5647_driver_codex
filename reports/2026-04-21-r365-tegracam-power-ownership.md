# 2026-04-21 r36.5 Tegracam Power Ownership Fix

## Context

- full V4L2-registration unload still hard-hangs with the currently loaded older module;
- `skip_v4l2_register=1` load/unload succeeds;
- the isolated unload path previously produced a `devm_kfree` warning during `tegracam_device_unregister()`;
- the current kernel still has the older full module loaded, so this checkpoint does not run `rmmod`, `insmod`, or streaming.

## Official Source Check

- NVIDIA r36.5 public BSP sources were downloaded from:
  - <https://developer.nvidia.com/downloads/embedded/l4t/r36_release_v5.0/sources/public_sources.tbz2>
- Relevant local reference subset:
  - `artifacts/reference/nvidia-r36.5/kernel_oot/nvidia-oot/drivers/media/platform/tegra/camera/tegracam_core.c`
  - `artifacts/reference/nvidia-r36.5/kernel_oot/nvidia-oot/drivers/media/platform/tegra/camera/tegracam_v4l2.c`
  - `artifacts/reference/nvidia-r36.5/kernel_oot/nvidia-oot/drivers/media/i2c/nv_imx219.c`
- Key finding:
  - `tegracam_device_register()` allocates framework-owned `s_data->power`;
  - `tegracam_device_unregister()` later frees `tc_dev->s_data->power`;
  - sensor drivers must fill that object, not replace it with private embedded storage.
- Reference grep saved:
  - `logs/20260421T094046Z-nvidia-r365-tegracam-reference-grep.log`

## Driver Change

- removed private embedded `struct camera_common_power_rail` from `struct ov5647`;
- changed `ov5647_power_get()` to use the framework-owned `s_data->power`;
- changed `ov5647_power_put()` to clear fields in the framework-owned object without freeing or replacing it;
- removed private reset/pwdn initialization from probe.

## Validation

- module build passed:
  - `logs/20260421T093958Z-build_module-power-ownership.log`
- `modinfo` passed and shows expected diagnostic parameters:
  - `logs/20260421T094009Z-modinfo-power-ownership.log`
- `git diff --check` passed:
  - `logs/20260421T094009Z-git-diff-check-power-ownership.log`
- grep check found no remaining private power-rail object or `s_data->power =` assignment in project sources:
  - `logs/20260421T094009Z-power-ownership-grep.log`

## Runtime Status

- not runtime-validated yet;
- the loaded kernel module is older than this rebuilt `.ko`;
- full `rmmod` remains unsafe until the user explicitly runs the next manual test.

## Next Smallest Step

Wait for a safe opportunity to manually unload the currently loaded older module or reboot into a clean state. After that, load the rebuilt module and test one narrow lifecycle path before returning to streaming.
