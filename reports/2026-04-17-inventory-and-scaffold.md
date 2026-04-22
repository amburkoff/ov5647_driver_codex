# 2026-04-17 Inventory And Scaffold Checkpoint

## What Changed

- created the required repository layout: `docs/`, `reports/`, `logs/`, `artifacts/`, `scripts/`, `patches/`, `src/`, `tools/`;
- replaced the placeholder `README.md` with a project status overview;
- added baseline project documents `docs/00` through `docs/11`, including the required `docs/01a-clb-carrier-mapping.md`;
- added log collection, build, boot-profile, and baseline test scripts under `scripts/`;
- added a non-probing external kernel module skeleton at `src/nv_ov5647/`;
- captured the first live environment, boot, DT, and kernel-log artifacts under `logs/` and `artifacts/`.

## Files Changed

- documentation: `README.md`, `docs/*.md`
- scripts: `scripts/*.sh`
- driver skeleton: `src/nv_ov5647/Makefile`, `src/nv_ov5647/nv_ov5647.c`
- support files: `.gitignore`, `patches/README.md`, `tools/README.md`

## Commands Run

- live inventory:
  - `uname -a`
  - `cat /etc/nv_tegra_release`
  - `cat /proc/cmdline`
  - `cat /proc/device-tree/model`
  - `tr -d '\0' < /proc/device-tree/chosen/ids`
  - `tr -d '\0' < /proc/device-tree/chosen/nvidia,sku`
  - `dtc -I fs -O dts /proc/device-tree`
  - `i2cdetect -l`
  - `lsmod`
  - `dpkg-query ... nvidia-l4t-*`
  - `apt-cache policy nvidia-jetpack nvidia-l4t-core nvidia-l4t-kernel`
- boot inspection:
  - `sed -n '1,240p' /boot/extlinux/extlinux.conf`
  - `./scripts/switch_boot_profile.sh --render-only --default safe`
- build and smoke:
  - `./scripts/build_module.sh`
  - `./scripts/run_smoke_tests.sh`
  - `./scripts/run_v4l2_tests.sh`
  - `./scripts/run_argus_tests.sh`
- log capture:
  - `./scripts/collect_env.sh`
  - `./scripts/capture_kernel_logs.sh`

## Logs Saved

Key log groups:

- environment inventory:
  - `logs/20260417T100915Z-collect_env.log`
  - `logs/20260417T100915Z-uname.log`
  - `logs/20260417T100915Z-nv_tegra_release.log`
  - `logs/20260417T100915Z-cmdline.log`
  - `logs/20260417T100915Z-date.log`
  - `logs/20260417T100915Z-uptime-s.log`
  - `logs/20260417T100915Z-journalctl-list-boots.log`
- kernel logs:
  - `logs/20260417T100815Z-dmesg.log`
  - `logs/20260417T100815Z-journalctl-k.log`
  - `logs/20260417T100815Z-journalctl-k-b.log`
- build and smoke:
  - `logs/20260417T100753Z-build_module.log`
  - `logs/20260417T100815Z-run_smoke_tests.log`
  - `logs/20260417T100815Z-run_v4l2_tests.log`
  - `logs/20260417T100816Z-run_argus_tests.log`
- DT and boot artifacts:
  - `artifacts/device-tree/20260417T100915Z/live-device-tree.dts`
  - `artifacts/boot/20260417T100722Z/extlinux.conf.current`
  - `artifacts/boot/20260417T100722Z/extlinux.conf.generated`
  - `artifacts/reference-overlays/20260417T100915Z/tegra234-p3767-camera-p3768-imx219-A.dts`
  - `artifacts/reference-overlays/20260417T100915Z/tegra234-p3767-camera-p3768-imx219-C.dts`
- build artifacts:
  - `artifacts/build/20260417T100753Z/nv_ov5647.ko`
  - `artifacts/build/20260417T100753Z/nv_ov5647.modinfo.txt`

## Tests Passed

- repository scaffold created successfully;
- all added shell scripts passed `bash -n`;
- `collect_env.sh` completed successfully;
- `capture_kernel_logs.sh` completed successfully after handling restricted `dmesg`;
- `switch_boot_profile.sh --render-only` generated a safe/dev `extlinux.conf` candidate without modifying `/boot`;
- `build_module.sh` built `nv_ov5647.ko` successfully against the running kernel headers;
- `run_smoke_tests.sh` completed and saved baseline state;
- `run_v4l2_tests.sh` ran and correctly reported missing `v4l2-ctl`;
- `run_argus_tests.sh` ran and saved current environment availability.

## Tests Failed Or Blocked

- full `dmesg` buffer access is blocked for the current unprivileged user and only the permission failure text was captured;
- `v4l2-ctl`, `media-ctl`, and `v4l2-compliance` are not installed, so V4L2 validation is blocked;
- no camera overlay is active and no `/dev/video*` nodes exist yet;
- physical CLB carrier mapping is still unresolved.

## Findings

- the running system identifies itself as NVIDIA reference carrier `p3768-0000+p3767-0000`, not yet as a verified CLB-specific carrier;
- current `extlinux.conf` has only one live label, `primary`, and no `boot_profile=*` token;
- generated safe/dev entries are ready for review and remain non-applied;
- the camera base I2C alias in the live DT points to `i2c@3180000`, which is Linux bus `i2c-2`;
- NVIDIA reference overlays on disk show devkit-style candidates:
  - `A`: `cam_i2cmux/i2c@0`, `serial_b`, `port-index = 1`, `bus-width = 2`
  - `C`: `cam_i2cmux/i2c@1`, `serial_c`, `port-index = 2`, `bus-width = 2`
- `journalctl --list-boots` and `uptime -s` disagree on boot start timing, so timestamp interpretation needs care.

## Current Root-Cause Hypotheses

- The board is either actually running a stock `p3768` device-tree image, or the supposed CLB carrier does not yet provide a DT-level identity override.
- Camera wiring is not discoverable from the current live DT because no sensor overlay is active.
- The fastest safe next blocker is physical and carrier-document verification, not immediate driver probe code.

## Next Smallest Step

1. Physically verify the carrier board identity and revision on the hardware.
2. Record the exact OV5647 cable and any adapter board in use.
3. Decide whether the real connector path corresponds to p3768 connector `A`, connector `C`, or a carrier-specific route.
4. Only then start the first probe-capable OV5647 driver revision and the first minimal overlay draft.

## Reboot

- reboot required now: `no`
- live default boot label: `primary`
- generated safe/dev candidate applied: `no`

