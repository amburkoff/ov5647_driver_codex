# Results And Status

Current overall status: `inventory, safe scaffold, corrected dev overlay boot, first controlled probe, and mclk bring-up debugging`

Completed:

- live platform inventory gathered from the target;
- timestamped logs written under `logs/`;
- DT and boot snapshots written under `artifacts/`;
- repository layout created;
- baseline documentation added;
- log collection scripts added;
- safe and dev boot profile generation workflow added;
- candidate `extlinux.conf` for safe/dev rendered under `artifacts/boot/20260417T100722Z/`;
- non-probing `nv_ov5647` external module skeleton added;
- `nv_ov5647.ko` build validated under `artifacts/build/20260417T100753Z/`;
- `nv_ov5647` upgraded to a gated OV5647 driver scaffold with `tegracam` and `camera_common` hooks;
- build against NVIDIA camera framework symbols validated under `artifacts/build/20260417T105242Z/`;
- root-validated `insmod` and `rmmod` completed successfully with the default safety gate;
- 10-cycle safe module lifecycle stress test completed successfully;
- `i2c_add_driver` and `i2c_del_driver` path validated with `register_i2c_driver=1 allow_hw_probe=0`.
- scaffold driver DT defaults aligned with NVIDIA-style supply names `vana`, `vdig`, and `vif`;
- compile-ready OV5647 draft overlay added for reference route `A`;
- local draft overlay build validated under `artifacts/dtbo/20260417T120134Z-ov5647-p3768-port-a-draft.dtbo`.
- safe/dev boot entries applied to `/boot/extlinux/extlinux.conf`;
- `DEFAULT` now points to `ov5647-safe` on disk;
- base camera I2C bus inventory confirms `i2c-2` exists, but no downstream camera devices are currently visible without an active camera overlay.
- reusable overlay build pipeline added through `scripts/build_overlay.sh`;
- route-A probe-oriented overlay candidate compiles under `artifacts/dtbo/20260417T124633Z-ov5647-p3768-port-a-probe.dtbo`.
- route-A probe overlay staged into `/boot/ov5647-p3768-port-a-probe.dtbo`;
- first dev reboot completed successfully and confirmed `boot_profile=ov5647-dev`;
- first dev reboot showed that `FDTOVERLAYS` did not apply the custom camera overlay on this target;
- boot tooling was corrected to UEFI-style `FDT + OVERLAYS`;
- a second dev reboot with the corrected `OVERLAYS` syntax completed successfully without a boot hang;
- the corrected dev boot now applies the custom probe overlay into the live DT;
- live DT now contains `cam_i2cmux`, `ov5647_a@36`, `tegra_sinterface = "serial_b"`, `lane_polarity = "6"`, and `bus-width = <2>`;
- the muxed downstream camera I2C bus appears as `i2c-9`;
- pstore evidence from the previous unexpected reboot was captured and tied to a kernel panic in `nv_ov5647` during `insmod`;
- the `tegracam_set_privdata()` ordering bug that caused the kernel panic has been fixed in the driver;
- controlled `insmod` no longer panics the kernel on the current code;
- current controlled probe reaches regulator and clock acquisition, then fails cleanly at `mclk get` with `err=-2`;
- the probe overlay source was updated to add an explicit `clocks = <&bpmp 0x07>` binding for `extperiph1`;
- the updated probe overlay has been rebuilt and staged to `/boot/ov5647-p3768-port-a-probe.dtbo` for the next reboot.

Not completed yet:

- CBL carrier identity confirmation from hardware documentation or physical inspection;
- verified OV5647 DT overlay;
- successful `mclk` acquisition in probe;
- OV5647 chip-ID read;
- confirmed sensor response at `0x36` on the muxed downstream bus;
- chip-ID read;
- `/dev/videoX`;
- raw capture;
- live preview.

Next smallest safe step:

- reboot once more into `ov5647-dev` so the updated overlay with the explicit clock phandle is applied;
- confirm the live DT now carries the new clock binding;
- rerun the controlled module probe and verify whether `mclk get failed err=-2` is resolved;
- if `mclk` comes up, continue immediately to power-on sequencing and chip-ID read;
- if `mclk` still fails, compare the live clock phandle and sample camera DT bindings against the active BSP DT before changing any other variable.
