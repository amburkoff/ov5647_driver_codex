# Results And Status

Current overall status: `inventory, safe scaffold, boot safety, and probe-overlay preparation`

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
- on-disk `extlinux.conf` now points `DEFAULT` to `ov5647-dev` for the next controlled reboot;
- the dev entry now carries `FDTOVERLAYS /boot/ov5647-p3768-port-a-probe.dtbo`.

Not completed yet:

- CBL carrier identity confirmation from hardware documentation or physical inspection;
- verified OV5647 DT overlay;
- first reboot into the prepared dev profile;
- OV5647 I2C probe;
- chip-ID read;
- `/dev/videoX`;
- raw capture;
- live preview.

Next smallest safe step:

- verify the physical CBL carrier identity and camera connector path;
- bind the first controlled single-sensor target to exactly one connector route;
- decide whether the first OV5647 DT enablement will be tested by rebooted `FDTOVERLAYS` flow or by another validated live-apply mechanism;
- install exactly one enabled OV5647 overlay on exactly one controlled test path;
- then attempt the first chip-ID probe with `allow_hw_probe=1`.
