# 2026-04-20 Post-Reboot Dev Overlay Investigation

## What Happened

- the system rebooted successfully into the prepared dev profile;
- `/proc/cmdline` confirmed:
  - `boot_profile=ov5647-dev`
- the system did not hang;
- `/dev/media0` was present after boot;
- the intended OV5647 overlay did **not** appear in the live device tree.

## Files Changed

- `scripts/switch_boot_profile.sh`
- `/boot/extlinux/extlinux.conf`

## Commands Run

- post-reboot collection:
  - `sudo ./scripts/collect_post_reboot.sh`
- live state checks:
  - `cat /proc/cmdline`
  - `lsmod`
  - `ls /dev/video* /dev/media*`
  - `sudo dmesg | grep ...`
  - `sudo dtc -I fs -O dts /proc/device-tree | grep ...`
- local NVIDIA tooling inspection:
  - `sed -n '1,260p' /opt/nvidia/jetson-io/Linux/extlinux.py`
  - `sed -n '360,460p' /opt/nvidia/jetson-io/Jetson/board.py`
  - `sudo python3 ... from Jetson import board; print(b.dtb)`
- corrected boot-profile application:
  - `sudo ./scripts/switch_boot_profile.sh --apply --default safe --dev-overlay /boot/ov5647-p3768-port-a-probe.dtbo`

## Logs Saved

- `logs/20260420T075214Z-collect_post_reboot.log`
- `logs/20260420T075456Z-switch_boot_profile.log`
- `logs/20260420T075512Z-revert-default-safe-uefi-style.log`
- `logs/20260420T075512Z-switch_boot_profile.log`

## Artifacts Saved

- `artifacts/post-reboot/20260420T075214Z/`
- `artifacts/boot/20260420T075456Z/extlinux.conf.current`
- `artifacts/boot/20260420T075456Z/extlinux.conf.generated`
- `artifacts/boot/20260420T075512Z/extlinux.conf.current`
- `artifacts/boot/20260420T075512Z/extlinux.conf.generated`

## Findings

- the dev profile itself is boot-stable;
- the overlay file on disk is intact and matched its expected checksum;
- the live DT after boot contained no `ov5647`, no `cam_i2cmux`, and no route-A camera nodes from the custom overlay;
- local NVIDIA `jetson-io` code for this platform does not use `FDTOVERLAYS`;
- local NVIDIA `jetson-io` writes boot entries in the form:
  - `FDT /boot/dtb/<board>.dtb`
  - `OVERLAYS /boot/<file>.dtbo`

## Root Cause Hypothesis

- the earlier dev entry used `FDTOVERLAYS`, which matches U-Boot-oriented documentation but not the locally installed NVIDIA UEFI/L4tLauncher flow on this r36.x target;
- because of that mismatch, the boot profile loaded, but the custom camera overlay was not merged into the kernel DT.

## Corrective Action Applied

- `scripts/switch_boot_profile.sh` was updated to generate UEFI-style boot entries using:
  - `FDT /boot/dtb/kernel_tegra234-p3768-0000+p3767-0000-nv.dtb`
  - `OVERLAYS /boot/ov5647-p3768-port-a-probe.dtbo`
- the on-disk boot default was returned to:
  - `DEFAULT ov5647-safe`
- the corrected dev entry remains available for the next controlled reboot.

## Tests Passed

- dev reboot completed successfully;
- post-reboot data collection succeeded;
- root cause was narrowed from “overlay content may be bad” to “bootloader overlay syntax mismatch”;
- corrected UEFI-style safe/dev boot config was rendered and applied on disk.

## Tests Failed

- the first dev reboot did not produce a live OV5647 node because the overlay was not applied.

## Next Smallest Step

1. Reboot again, this time with the corrected UEFI-style dev entry.
2. Confirm `boot_profile=ov5647-dev` again.
3. Check whether `ov5647_a@36` and route-A endpoints appear in live DT.
4. If the overlay is finally present, proceed to the first controlled probe.

## Reboot Needed

- Yes, but only after the corrected UEFI-style dev entry is made default.

## Default Boot Profile On Disk

- `ov5647-safe`
