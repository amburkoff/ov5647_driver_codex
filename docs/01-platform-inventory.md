# Platform Inventory

Inventory snapshot date: `2026-04-17`

## Confirmed Live Facts

| Item | Value | Source |
| --- | --- | --- |
| Kernel | `5.15.185-tegra` | `uname -a` |
| L4T release | `R36 (release), REVISION: 5.0` | `/etc/nv_tegra_release` |
| Installed L4T core package | `36.5.0-20260115194252` | `dpkg-query` |
| Installed L4T kernel package | `5.15.185-tegra-36.5.0-20260115194252` | `dpkg-query` |
| `nvidia-jetpack` apt candidate | `6.2.2+b24` | `apt-cache policy nvidia-jetpack` |
| Live DT model | `NVIDIA Jetson Orin NX Engineering Reference Developer Kit` | `/proc/device-tree/model` |
| Live DT compatible | `nvidia,p3768-0000+p3767-0000`, `nvidia,p3767-0000`, `nvidia,tegra234` | `/proc/device-tree/compatible` |
| Chosen board IDs | `3767-0000-301 3768-0000-ES1` | `/proc/device-tree/chosen/ids` |
| Chosen SKU | `699-13767-0000-301 G.1` | `/proc/device-tree/chosen/nvidia,sku` |
| Active cmdline boot token | `unset` | `/proc/cmdline` |
| Current extlinux default | `primary` | `/boot/extlinux/extlinux.conf` |
| Boot menu entries | only `LABEL primary` is active | `/boot/extlinux/extlinux.conf` |
| Base DTB on disk | `/boot/kernel_tegra234-p3768-0000+p3767-0000-nv.dtb` | `/boot` |
| Camera I2C alias | `cam_i2c -> /bus@0/i2c@3180000` | live DT decompile |
| Linux I2C bus for `i2c@3180000` | `i2c-2` | `/sys/bus/i2c/devices` |
| Current wall clock | `2026-04-17T13:09:15+03:00` | `date -Is` |
| `uptime -s` boot start | `2026-04-17 10:41:21` | `uptime -s` |

## Camera Stack State On The Running System

Confirmed:

- `tegra_camera`, `nvhost_vi5`, `nvhost_nvcsi_t194`, and related camera framework modules are loaded.
- `/dev/video*` and `/dev/media*` are currently absent.
- no live `cam_i2cmux`, `rbpcv2_*`, `imx219`, `imx477`, or `ov5647` camera sensor nodes were found in the active device tree.
- reference camera overlays for `imx219` and `imx477` are present in `/boot/`.

Missing toolchain pieces for validation:

- `v4l2-ctl` not installed;
- `media-ctl` not installed;
- `v4l2-compliance` not installed.

## Logging Caveats

- unprivileged `dmesg` access is restricted on this target, so log capture stores the permission failure text unless the collection is run with elevated privileges;
- `journalctl --list-boots` currently shows boot `0` starting on `2025-08-26 18:23:06 MSK`, while `uptime -s` reports `2026-04-17 10:41:21`;
- this mismatch strongly suggests a clock or journal timestamp discontinuity and must be kept in mind when interpreting persistent logs.

## Boot Configuration State

Current `extlinux.conf` state:

- one active entry: `primary`;
- `DEFAULT primary`;
- no `boot_profile=ov5647-safe` token;
- no `boot_profile=ov5647-dev` token;
- no experimental camera overlay or OV5647 boot-time auto-load configured.

This means the required safe/dev split does not exist yet on disk. The repository now includes scripts to generate and review a safe/dev candidate configuration before any root-level apply step.

## Reference Overlay Clues From NVIDIA BSP

Decompiled reference overlays on this target show the standard p3768 camera mapping pattern:

- `tegra234-p3767-camera-p3768-imx219-A.dtbo`
  - `cam_i2cmux/i2c@0`
  - `tegra_sinterface = "serial_b"`
  - `port-index = 1`
  - `bus-width = 2`
- `tegra234-p3767-camera-p3768-imx219-C.dtbo`
  - `cam_i2cmux/i2c@1`
  - `tegra_sinterface = "serial_c"`
  - `port-index = 2`
  - `bus-width = 2`

These are NVIDIA reference patterns only. They are not yet proof of the physical OV5647 wiring on the target carrier.
