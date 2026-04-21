# Results And Status

Current overall status: `inventory, safe scaffold, corrected dev overlay boot, successful single-sensor probe, first /dev/video0, passing v4l2-compliance, capture path reaches STREAMON but no frames yet, full unload hang isolated to V4L2 subdev/media graph path`

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
- the current dev boot now exposes a live route-A OV5647 path on:
  - `serial_b`
  - `port-index = 1`
  - `bus-width = <2>`
  - `lane_polarity = "6"`
- direct bus inspection confirms the muxed downstream camera bus is:
  - `i2c-9`
- direct hardware reads confirm a real OV5647 responder at:
  - `0x36`
  - chip ID `0x5647`
- the current path is probe-stable only when `pwdn_gpio=397` is kept high during power-on;
- with that change, `ov5647_board_setup()` now succeeds and logs the correct chip ID;
- after removing `TEGRA_CAMERA_CID_GROUP_HOLD` from the driver control list, `tegracam_v4l2subdev_register()` succeeds;
- the kernel now creates:
  - `/dev/video0`
  - `/dev/v4l-subdev0`
  - `/dev/v4l-subdev1`
- the VI stack logs:
  - `tegra-camrtc-capture-vi tegra-capture-vi: subdev nv_ov5647 9-0036 bound`
- the current manual probe exits successfully with no panic and no negative-probe unwind warning on the successful path.
- `v4l-utils` tooling is installed on the target and logging is wired into the repo workflow.
- `v4l2-compliance -d /dev/video0` previously completed successfully with all reported checks passing.
- a first manual capture path now executes through:
  - `ov5647_power_on`
  - `ov5647_set_mode`
  - `ov5647_start_streaming`
  - `ov5647_stop_streaming`
- the first capture attempt did not hang the Jetson, but produced no image data:
  - the raw output file was zero bytes;
  - VI reported repeated `uncorr_err: request timed out after 2500 ms`.
- the latest manual unload hang did not preserve any `module_exit` marker despite the loaded `.ko` containing the marker strings.
- a diagnostic `skip_v4l2_register` module parameter has been added to isolate chip-ID probe from V4L2 subdev/media graph registration.
- with `skip_v4l2_register=1`, manual `rmmod` returned successfully with `rmmod rc=0`.
- the isolated unload still reports a `devm_kfree` warning from `tegracam_device_unregister()`, but does not hang.
- after removing direct `ov5647_power_off()` from `remove()`, full V4L2-registration unload still hangs.
- unload helper now records media/video/subdev node holders through `fuser` and `lsof` before issuing `rmmod`.
- follow-up full-load inspection showed no userspace holders, module `refcnt=0`, and no module holders.
- current media graph is linked as `nv_ov5647 -> nvcsi -> vi-output`, with `/dev/video0` at `BG10 640x480`.
- prepared next-stage unload diagnostics:
  - `skip_v4l2_unregister`;
  - `split_v4l2_unregister`;
  - `unload_marker_delay_ms`.
- unload helper now supports optional `RMMOD_SYSRQ_DELAY_SEC` blocked-task watchdog.
- direct `scripts/unload_module.sh` now refuses unsafe unload unless `OV5647_ALLOW_UNSAFE_RMMOD=1` is explicitly set.
- added `scripts/run_manual_insmod_diag.sh` with `full-delay`, `skip-register`, `skip-unregister`, and `split-unregister` profiles.
- fixed OV5647 power rail ownership to use framework-owned `s_data->power` instead of an embedded private object.
- prepared upstream-aligned OV5647 sensor output-enable handling for power-on/power-off (`0x3000/0x3001/0x3002`), not runtime-tested yet.

Not completed yet:

- CBL carrier identity confirmation from hardware documentation or physical inspection;
- verified OV5647 DT overlay;
- verified OV5647 DT overlay for the actual physical connector used by the user;
- stable `rmmod`;
- raw capture with non-empty frame data;
- live preview.

Next smallest safe step:

- do not unload the currently loaded module from Codex; next risky unload must be manual and use the new marker-delay diagnostics after a fresh module load;
- continue aligning the minimal mode table and CSI timing until VI receives real frames instead of timing out;
- keep all further work on this single confirmed route-A / 2-lane / `0x36` path only.
