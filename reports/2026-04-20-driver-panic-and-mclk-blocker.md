# 2026-04-20 Driver Panic And MCLK Blocker

## What Changed

- investigated the unexpected reboot and preserved the reboot cause from `pstore`;
- fixed a kernel-panic bug in `nv_ov5647` probe ordering;
- added temporary probe-time instrumentation for DT parsing and power-resource acquisition;
- updated the route-A probe overlay to add an explicit `extperiph1` clock binding;
- rebuilt and restaged the probe overlay into `/boot/ov5647-p3768-port-a-probe.dtbo`.

## Files Changed

- `src/nv_ov5647/nv_ov5647.c`
- `patches/ov5647-p3768-port-a-probe.dts`
- `docs/10-results-and-status.md`
- `docs/11-known-issues.md`

## Commands Run

- reboot-cause investigation:
  - `last -x | head`
  - `sudo ls -l /sys/fs/pstore`
  - `sudo sed -n '1,220p' /sys/fs/pstore/dmesg-ramoops-0`
  - `sudo sed -n '1,220p' /sys/fs/pstore/dmesg-ramoops-1`
- current boot and DT checks:
  - `cat /proc/cmdline`
  - `sudo dtc -I fs -O dts /proc/device-tree`
  - `sudo i2cdetect -y 9`
- build and probe loop:
  - `./scripts/build_module.sh`
  - `sudo insmod ./src/nv_ov5647/nv_ov5647.ko register_i2c_driver=1 allow_hw_probe=1`
  - `sudo rmmod nv_ov5647`
- overlay rebuild and staging:
  - `./scripts/build_overlay.sh patches/ov5647-p3768-port-a-probe.dts`
  - `sudo install -m 0644 artifacts/dtbo/20260420T082008Z-ov5647-p3768-port-a-probe.dtbo /boot/ov5647-p3768-port-a-probe.dtbo`
  - `sha256sum artifacts/dtbo/20260420T082008Z-ov5647-p3768-port-a-probe.dtbo /boot/ov5647-p3768-port-a-probe.dtbo`

## Logs Saved

- `logs/20260420T080243Z-collect_post_reboot.log`
- `logs/20260420T080303Z-i2c-detect-bus9.log`
- `logs/20260420T081549Z-build_module.log`
- `logs/20260420T081603Z-probe-attempt-after-privdata-fix.log`
- `logs/20260420T081759Z-build_module.log`
- `logs/20260420T081814Z-probe-attempt-with-powerget-instrumentation.log`
- `logs/20260420T081830Z-build_module.log`
- `logs/20260420T081844Z-probe-attempt-after-tcdev-priv-fix.log`
- `logs/20260420T081933Z-build_overlay-ov5647-p3768-port-a-probe.log`
- `logs/20260420T082008Z-build_overlay-ov5647-p3768-port-a-probe.log`
- `logs/20260420T082024Z-stage-updated-probe-dtbo.log`

## Artifacts Saved

- `artifacts/post-reboot/20260420T080243Z/`
- `artifacts/build/20260420T081549Z/`
- `artifacts/build/20260420T081759Z/`
- `artifacts/build/20260420T081830Z/`
- `artifacts/dtbo/20260420T081933Z-ov5647-p3768-port-a-probe.dtbo`
- `artifacts/dtbo/20260420T082008Z-ov5647-p3768-port-a-probe.dtbo`

## Findings

- the previous unexpected reboot was a kernel panic, not a clean reboot;
- `pstore` preserved the panic trace and tied it to `nv_ov5647` during `insmod`;
- the panic signature was a NULL dereference through `tegracam_set_privdata()` in probe;
- after moving `tegracam_set_privdata()` until after `tegracam_device_register()` and pre-seeding `tc_dev->priv`, the kernel panic stopped reproducing;
- the current probe now fails cleanly in `ov5647_power_get()` with:
  - `mclk get failed err=-2`
- the live dev overlay is already sufficient to create:
  - `cam_i2cmux`
  - downstream `i2c-9`
  - `ov5647_a@36` sensor DT node
- the current live DT still does not provide a usable clock resource to the driver;
- the updated overlay source now adds:
  - `clocks = <&bpmp 0x07>;`
  - `clock-names = "extperiph1";`
- that updated overlay is staged on disk but is not yet active until the next reboot.

## Tests Passed

- unexpected reboot root cause narrowed to a concrete kernel panic in the driver;
- panic evidence preserved from ramoops;
- driver rebuilds succeed after the probe-ordering fix;
- manual `insmod` no longer crashes the kernel on the current code;
- the current failure mode is a clean probe failure, not a panic or hang;
- updated overlay rebuild succeeded and was staged to `/boot`.

## Tests Failed

- current probe still fails before power-on completion because the active live DT lacks a usable `mclk` binding;
- no chip-ID read yet;
- no visible I2C response at `0x36` on `i2c-9`;
- no `/dev/videoX` yet.

## Root-Cause Hypotheses

- confirmed root cause for the spontaneous reboot:
  - probe called `tegracam_set_privdata()` before the tegracam device had been registered into the expected internal state;
- current blocker hypothesis:
  - the active live DT is still using the earlier overlay revision, so the sensor node does not yet expose a clock provider that `camera_common_mclk_enable()` can resolve.

## Next Smallest Step

1. Reboot once into the already prepared `ov5647-dev` profile so the updated overlay is applied.
2. Confirm `boot_profile=ov5647-dev` and verify the live sensor node includes `clocks` and `clock-names`.
3. Retry the manual probe.
4. If `mclk` succeeds, continue directly to chip-ID read and board-setup logging.
5. If `mclk` still fails, inspect the active DT clock phandle and compare it with local NVIDIA camera DT examples before changing GPIO or regulator assumptions.

## Reboot Needed

- Yes.
- Reason: the updated overlay with the explicit `clocks` binding is already staged in `/boot`, but DT overlay changes only take effect after reboot.

## Default Boot Profile On Disk

- `ov5647-dev`
