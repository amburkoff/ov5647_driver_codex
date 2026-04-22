# Results And Status

Current overall status: `route-A corrected-MCLK capture also no-SOF, manual LKM-only workflow retained, route-A and route-C probes work, remove path fixed, physical CLB/makerobo CSI path now the dominant blocker`

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
- latest manual `rmmod` hang occurred with an older loaded module that did not contain the new split-unregister diagnostics or output-enable fix.
- after user rebooted and accidentally ran a second `sudo reboot`, the system is clean with no `nv_ov5647` loaded; pstore contains only the later clean reboot trail.
- manual `split-unregister` insmod succeeded with the rebuilt module; query-only V4L2/media checks show `/dev/video0`, `BG10 640x480`, and a linked media graph.
- first single-frame capture after the output-enable fix reached `VIDIOC_STREAMON` but timed out after 30 seconds with a zero-byte raw file; cleanup path ran `stop_streaming` and `power_off`.
- prepared source-side fix so `ov5647_set_mode()` leaves the sensor in standby and only `ov5647_start_streaming()` writes `0x0100=STREAMING`.
- latest manual `rmmod` hang is localized by live-dmesg to:
  - `module exit enter`
  - `before i2c_del_driver`
  - `ov5647_remove: enter`
  - skipped V4L2 unregister because the private `v4l2_registered` flag was false
  - `before tegracam_device_unregister`
- pstore after that hang is empty, so the live-dmesg boundary is the primary evidence.
- source-side remove fix is prepared so full-probe remove forces V4L2 unregister whenever `s_data` exists and `skip_v4l2_register=0`, even if the private flag is inconsistent.
- rebuilt `nv_ov5647.ko` contains the new forced-unregister warning and state dump markers.
- a follow-up manual split-unregister unload still hung, but the new state dump revealed the root cause:
  - `ov5647_remove()` used `i2c_get_clientdata(client)` as `struct tegracam_device *`;
  - after V4L2 subdev init, I2C clientdata points to the V4L2 subdev, not the tegracam device;
  - remove was therefore operating on a miscast pointer.
- source-side fix is prepared to use NVIDIA sample-style remove lookup:
  - `to_camera_common_data(&client->dev)`
  - `s_data->priv`
  - `priv->tc_dev`
- rebuilt `nv_ov5647.ko` contains the corrected remove lookup and additional probe/remove state markers.
- manual full-probe unload after the corrected remove lookup succeeded with `rmmod rc=0`.
- the successful unload completed:
  - `v4l2_ctrl_handler_free`
  - `v4l2_async_unregister_subdev`
  - `media_entity_cleanup`
  - `tegracam_device_unregister`
  - `i2c_del_driver`
- remove-time state is now valid:
  - `s_data->priv` is non-NULL;
  - `tc_dev->dev` is non-NULL;
  - `v4l2_registered=1`.
- manual normal-path full-probe unload also succeeded with `split_v4l2_unregister=0` and `rmmod rc=0`.
- the normal NVIDIA tegracam unregister path now completes through:
  - `tegracam_v4l2subdev_unregister`
  - VI subdev unbind
  - `tegracam_device_unregister`
  - `i2c_del_driver`
- after a clean normal remove checkpoint and fresh full-delay load, the next manual single-frame capture reached `VIDIOC_STREAMON` but still produced no frame data:
  - capture command returned `rc=124` after the 30 second timeout;
  - raw output `artifacts/captures/20260421T151642Z/ov5647-640x480-bg10.raw` is zero bytes;
  - VI logged repeated `uncorr_err: request timed out after 2500 ms`;
  - driver logs show `power_on`, `set_mode`, `start_streaming`, `stop_streaming`, and `power_off` all returned without hanging.
- current source comparison against upstream Linux OV5647 shows the local 640x480 table is not identical to upstream VGA mode:
  - upstream uses `0x3821 = 0x03`;
  - the local table currently uses `0x3821 = 0x01`;
  - the local VGA table also contains additional `0x5002` and `0x4837` writes that are not present in upstream VGA mode.
- a stronger upstream difference was found in the power-on path:
  - upstream OV5647 writes a stream-stop sequence after output-enable to put CSI lanes into LP-11;
  - the local driver did not do this before the zero-byte capture test.
- source-side LP-11 power-on fix is now prepared and builds:
  - `ov5647_power_on()` writes the upstream stream-stop sequence after output-enable;
  - `ov5647_stop_streaming()` now uses the same helper;
  - rebuilt `.ko` contains `stream-stop LP-11 setup complete`.
- runtime validation of the LP-11 fix completed:
  - manual `rmmod` returned cleanly;
  - manual `insmod full-delay` returned cleanly and `/dev/video0` appeared;
  - dmesg confirms the new `stream-stop LP-11 setup complete` marker executed;
  - single-frame capture still timed out with `rc=124` and a zero-byte raw file.
- the next source-side hypothesis is incomplete mode timing:
  - upstream OV5647 mode data defines VGA `hts = 1852` and `vts = 0x1f8`;
  - upstream applies HTS/VTS through controls;
  - the local tegracam control callbacks are still stubs, so the minimal mode table should explicitly program HTS/VTS for the single 640x480 mode.
- source-side HTS/VTS mode fix is prepared:
  - `0x380c/0x380d = 0x073c` for upstream VGA HTS 1852;
  - `0x380e/0x380f = 0x01f8` for upstream VGA VTS;
  - runtime validation has now been run.
- runtime validation of the HTS/VTS mode fix still timed out:
  - manual `rmmod` returned cleanly before the test cycle;
  - manual `insmod full-delay` returned cleanly and `/dev/video0` appeared;
  - single-frame capture reached `VIDIOC_STREAMON`;
  - capture returned `rc=124` after the 30 second timeout;
  - raw output `artifacts/captures/20260421T153826Z/ov5647-640x480-bg10.raw` is zero bytes;
  - VI still logged repeated `uncorr_err: request timed out after 2500 ms`;
  - driver cleanup logs show `stop_streaming` and `power_off` returned successfully.
- read-only route analysis after the HTS/VTS timeout confirmed the current route-A overlay matches NVIDIA's installed p3768 `imx219-A`/`imx477-A` route fields:
  - `cam_i2cmux/i2c@0`;
  - `serial_b`;
  - `port-index = 1`;
  - `bus-width = 2`;
  - `lane_polarity = 6`;
  - GPIO token `0x3e`.
- source-side VGA mode cleanup is prepared and builds:
  - removed local-only `0x5002 = 0x41`;
  - removed local-only `0x4837 = 0x16`;
  - kept Raspberry Pi 6.6.y-compatible `0x3821 = 0x01`;
  - rebuilt `.ko` has `srcversion=2F4050CDED69B8A5FF0C49F`.
- runtime validation of the VGA table cleanup still timed out:
  - loaded module `srcversion=2F4050CDED69B8A5FF0C49F`;
  - `rmmod` and `insmod full-delay` completed cleanly;
  - single-frame capture reached `VIDIOC_STREAMON`;
  - capture returned `rc=124`;
  - raw output `artifacts/captures/20260421T155031Z/ov5647-640x480-bg10.raw` is zero bytes;
  - VI still logged repeated `uncorr_err: request timed out after 2500 ms`.
- alternate route-C overlay candidate is prepared and builds:
  - source `patches/ov5647-p3768-port-c-probe.dts`;
  - built artifact `artifacts/dtbo/20260421T155351Z-ov5647-p3768-port-c-probe.dtbo`;
  - route fields: `cam_i2cmux/i2c@1`, `serial_c`, `port-index=2`, `bus-width=2`, `pwdn-gpios=<... 0xa0 ...>`, `lane_polarity="0"`;
  - route-C boot config was rendered under `artifacts/boot/20260421T155412Z/`.
- route-C boot staging is now applied for the next reboot:
  - `/boot/ov5647-p3768-port-c-probe.dtbo` staged;
  - `DEFAULT ov5647-dev`;
  - dev entry uses `OVERLAYS /boot/ov5647-p3768-port-c-probe.dtbo`;
  - safe entry remains available and has no OV5647 overlay;
  - previous extlinux backed up as `/boot/extlinux/extlinux.conf.20260421T155602Z.bak`.
- route-C post-reboot validation passed:
  - system booted with `boot_profile=ov5647-dev`;
  - live DT contains `ov5647_c@36` under `cam_i2cmux/i2c@1`;
  - live route uses `serial_c`, `port-index=2`, `bus-width=2`, and `lane_polarity="0"`;
  - `i2c-9` now maps to mux `chan_id 1`, route C;
  - pstore is empty;
  - `nv_ov5647` is not loaded and `/dev/video0` is absent before manual LKM load, as expected.
- route-C manual `insmod full-delay` succeeded:
  - loaded module `srcversion=2F4050CDED69B8A5FF0C49F`;
  - probe read chip ID `0x5647`;
  - route-C `pwdn_gpio` resolved to Linux GPIO `486`;
  - `/dev/video0`, `/dev/v4l-subdev0`, and `/dev/v4l-subdev1` appeared;
  - media graph links are enabled from `nv_ov5647 9-0036` to `nvcsi` to `vi-output`;
  - V4L2 reports `BG10 640x480` on `platform:tegra-capture-vi:2`.
- route-C manual single-frame capture still timed out:
  - capture reached `VIDIOC_STREAMON`;
  - capture returned `rc=124`;
  - raw output `artifacts/captures/20260422T080247Z/ov5647-640x480-bg10.raw` is zero bytes;
  - VI still logged repeated `uncorr_err: request timed out after 2500 ms`;
  - driver cleanup logs show `stop_streaming` and `power_off` returned successfully.
- source-side no-duplicate-set-mode experiment is prepared and builds:
  - removed duplicate `ov5647_set_mode()` from `ov5647_start_streaming()`;
  - this avoids re-applying common/mode tables and software reset `0x0103` immediately before stream enable;
- runtime validation of the no-duplicate-set-mode experiment still timed out:
  - manual `rmmod` returned cleanly;
  - manual `insmod full-delay` loaded module `srcversion=E9CE1D1EF58B852F6484431`;
  - the new `ov5647_start_streaming: using mode already applied by tegracam set_mode` marker executed;
  - single-frame capture reached `VIDIOC_STREAMON`;
  - capture returned `rc=124`;
  - raw output `artifacts/captures/20260422T080757Z/ov5647-640x480-bg10.raw` is zero bytes;
  - VI still logged repeated `uncorr_err: request timed out after 2500 ms`;
  - driver cleanup logs show `stop_streaming` and `power_off` returned successfully.

Current blocking issue:

- `/dev/video0` exists and the module lifecycle is now stable enough for manual testing, but no CSI frames are delivered on route A or route C.
- The next safest source-side step is a diagnostic register readback dump around mode programming and stream enable, to verify the sensor's actual register state before changing more timing or DT assumptions.
- diagnostic stream-register readback is now prepared and builds:
  - new module parameter `dump_stream_regs`, default `false`;
  - new manual insmod profile `full-delay-dump`;
  - rebuilt `.ko` `srcversion=E6D2A445F8276648D752078`;
  - runtime validation has now been run.
- diagnostic stream-register runtime validation still timed out, but exposed a concrete driver defect:
  - manual `rmmod` returned `rc=0`;
  - manual `insmod full-delay-dump` returned `rc=0`;
  - capture reached `VIDIOC_STREAMON`;
  - capture returned `rc=124` and raw output is zero bytes;
  - at `power_on_lp11`, output-enable registers are `0x3000=0x0f`, `0x3001=0xff`, `0x3002=0xe4`;
  - after `set_mode()`, output-enable registers are reset to `0x3000=0x00`, `0x3001=0x00`, `0x3002=0x00`;
  - after stream-on, `0x0100=0x01`, but `0x3000/0x3001/0x3002` remain disabled;
  - next source-side fix is to re-enable sensor output after mode programming / before stream start.
- source-side output-enable restore fix is prepared and builds:
  - `ov5647_set_mode()` now restores `0x3000/0x3001/0x3002` after mode programming;
  - `ov5647_start_streaming()` restores the same output-enable table again before `0x0100=0x01`;
  - rebuilt `.ko` `srcversion=96FCD7FB15E34D8DE37E4F2`;
  - runtime validation has now been run.
- runtime validation of the output-enable restore fix still timed out, but the register defect is confirmed fixed:
  - manual `rmmod` returned `rc=0`;
  - manual `insmod full-delay-dump` returned `rc=0`;
  - loaded `.ko` `srcversion=96FCD7FB15E34D8DE37E4F2`;
  - after `set_mode()`, `0x3000=0x0f`, `0x3001=0xff`, `0x3002=0xe4`;
  - after stream-on, `0x0100=0x01` and `0x3000/0x3001/0x3002` remain restored;
  - capture still returned `rc=124`, raw output is zero bytes, and VI still logged timeout errors.

Current next focus:

- output-enable is no longer the primary blocker;
- continue with one-variable analysis of MIPI stream-start sequencing and DT timing before larger DT/hardware-route changes.
- continuous MIPI clock diagnostic experiment is prepared and builds:
  - upstream Linux OV5647 writes `0x4800=0x04` by default and uses `0x34` only for non-continuous clock;
  - current local driver default remains `0x34`;
  - new gated module parameter `continuous_mipi_clock=1` selects `0x4800=0x04`;
  - new manual profile `full-delay-dump-contclk` is available;
  - rebuilt `.ko` `srcversion=92FD1291C5FC74E28DC6E26`;
  - runtime validation has now been run.
- runtime validation of the continuous MIPI clock experiment still timed out:
  - manual `rmmod` returned `rc=0`;
  - manual `insmod full-delay-dump-contclk` returned `rc=0`;
  - loaded `.ko` `srcversion=92FD1291C5FC74E28DC6E26`;
  - `continuous_mipi_clock=1`;
  - `ov5647_start_streaming` used `mipi_ctrl00 stream value=0x04`;
  - readback confirmed `after_stream_on 0x4800=0x04`;
  - readback also confirmed `0x0100=0x01` and output-enable registers remain restored;
  - capture still returned `rc=124`, raw output is zero bytes, and VI still logged timeout errors.

Current next focus:

- simple stream-start bit fixes are not enough;
- focus must shift to DT timing, lane polarity/ordering, physical adapter compatibility, or missing mode-table registers.
- route-C continuous-clock DT experiment is prepared:
  - `patches/ov5647-p3768-port-c-probe.dts` now sets `discontinuous_clk = "no"`;
  - built DTBO artifact `artifacts/dtbo/20260422T082931Z-ov5647-p3768-port-c-probe.dtbo`;
  - staged separate boot DTBO `/boot/ov5647-p3768-port-c-contclk.dtbo`;
  - rendered candidate boot config exists at `artifacts/boot/20260422T082942Z/extlinux.conf.generated`;
  - safe profile remains present in the current and rendered boot configs.
- route-C continuous-clock dev boot is now staged:
  - current `/boot/extlinux/extlinux.conf` uses `DEFAULT ov5647-dev`;
  - dev entry uses `OVERLAYS /boot/ov5647-p3768-port-c-contclk.dtbo`;
  - safe profile remains present with `boot_profile=ov5647-safe`;
  - previous extlinux was backed up as `/boot/extlinux/extlinux.conf.20260422T083143Z.bak`;
  - reboot is required to validate this DT change.
- route-C continuous-clock post-reboot validation passed:
  - `/proc/cmdline` contains `boot_profile=ov5647-dev`;
  - live DT contains `discontinuous_clk = "no"` under `ov5647_c@36/mode0`;
  - `/boot/extlinux/extlinux.conf` still retains the safe profile and uses `DEFAULT ov5647-dev`;
  - `nv_ov5647` is not auto-loaded;
  - `/dev/video0` is absent before manual LKM load, as expected;
  - `/dev/media0` is present;
  - pstore contains `console-ramoops-0`, but the captured head is an early boot log for the current `boot_profile=ov5647-dev` boot and is not, by itself, evidence of a new panic.
- route-C continuous-clock runtime capture was tested manually after reboot:
  - loaded module `srcversion=92FD1291C5FC74E28DC6E26`;
  - module parameters confirmed `continuous_mipi_clock=Y` and `dump_stream_regs=Y`;
  - `VIDIOC_STREAMON` returned success;
  - after stream-on, readback showed `0x0100=0x01`, `0x4800=0x04`, and output-enable registers `0x3000=0x0f`, `0x3001=0xff`, `0x3002=0xe4`;
  - capture still timed out with `rc=124`;
  - raw output `artifacts/captures/20260422T085016Z/ov5647-640x480-bg10.raw` is zero bytes;
  - VI still reports repeated `uncorr_err: request timed out after 2500 ms`.
- RTCPU/NVCSI trace tooling is prepared for the next manual capture attempt:
  - `scripts/run_manual_single_frame_rtcpu_trace.sh`;
  - expected artifacts under `artifacts/traces/<timestamp>/`.
- RTCPU/NVCSI traced capture was tested manually:
  - raw output `artifacts/captures/20260422T085920Z/ov5647-640x480-bg10.raw` is zero bytes;
  - trace contains power-on, capture setup, IVC submit, CSI stream enable, and sensor stream enable events;
  - trace contains no `vi_frame_begin`, no `vi_frame_end`, no `rtcpu_vinotify_error`, no `rtcpu_nvcsi_intr`, no `capture_event_sof`, and no `capture_event_error`;
  - RTCPU `last_exception` is empty and stats show `Exceptions: 0`;
  - current evidence points to no CSI frame start reaching NVCSI/VI, not to frames arriving with a reported NVCSI decode error.

Not completed yet:

- CLB carrier schematic/revision confirmation beyond user-reported kit name, makerobo box marking, and official Developer Kit flashing booklet;
- verified OV5647 DT overlay;
- verified OV5647 DT overlay for the actual physical connector used by the user;
- raw capture with non-empty frame data;
- live preview.

Next smallest safe step:

- do not run `insmod`, `rmmod`, capture, stream, or reboot from Codex; next risky runtime test must be manual to preserve Codex CLI context if the Jetson hangs;
- ask the user to manually run one RTCPU/NVCSI traced capture on the already loaded route-C continuous-clock module;
- do not tune more simple stream-start bits until the physical CSI path, lane mapping/polarity, and adapter compatibility are re-checked against this no-SOF evidence.

Update after read-only route snapshot work:

- current safe state after later reboot/manual operations:
  - `/proc/cmdline` still contains `boot_profile=ov5647-dev`;
  - `nv_ov5647` is currently not loaded;
  - `/dev/video0` is absent before manual LKM load;
  - route-C overlay remains live in DT;
- new read-only helper added:
  - `scripts/collect_camera_route_state.sh`;
  - it saves cmdline, extlinux, I2C bus list, module state, media graph, live DT route fields, and a live DT dump without loading/unloading the module or starting streaming;
- latest safe route snapshot:
  - `artifacts/camera-route-state/20260422T132108Z/`;
  - confirms active `ov5647_c@36` with `serial_c`, endpoint `port-index = <2>`, endpoint `bus-width = <2>`, `lane_polarity = "0"`, and `discontinuous_clk = "no"`;
  - confirms stale `ov5647_a@36` is present but `status = "disabled"`;
  - confirms `i2c-9` is `i2c-2-mux (chan_id 1)` and `i2c-10` is `chan_id 0`.

Revised next smallest safe step:

- keep runtime tests manual-only;
- prioritize physical route validation or a known-good Jetson camera cross-check before more DT/register variants.

Hardware naming correction:

- User corrected the carrier name to `CLB Developer Kit`; earlier project notes used a mistyped carrier name.
- User reports the box identifies it as a partner board from `makerobo`.
- User reports the included booklet says to install the Jetson image from the official Developer Kit site.
- Reasoning update: the live NVIDIA `p3768` DT identity is now expected for this installed image, but still does not prove that the CLB camera connector, adapter, lane polarity, and cable orientation match the p3768 reference carrier electrically.

Update after MCLK diagnostic patch:

- NVIDIA r36.5 `camera_common_mclk_enable()` sets the sensor clock to `s_data->def_clk_freq`;
- `tegracam_core` derives `s_data->def_clk_freq` from DT `mclk_khz * 1000`;
- the live route-C DT mode currently has `mclk_khz = "24000"`, so the expected enabled MCLK is 24 MHz;
- the external `extperiph1` clock shows 51 MHz while the module is not loaded, but that idle clock-summary state does not prove the active sensor power-on rate;
- driver-side diagnostic logs were added for:
  - MCLK rate after `devm_clk_get()`;
  - DT-derived `def_clk_freq` before power-on;
  - effective MCLK rate after `camera_common_mclk_enable()`;
  - MCLK rate before power-off;
- diagnostic-only module parameter `mclk_override_hz` was added, default `0`;
- manual insmod profile `full-delay-dump-contclk-mclk24` was added and passes `mclk_override_hz=24000000`;
- module build passed after the patch;
- no risky runtime command was run from Codex after this patch.

Next manual runtime test:

- if `nv_ov5647` is loaded, unload only if the current session can tolerate a hang; otherwise reboot/power-cycle first and keep Codex CLI context intact;
- manually run `sudo /home/cam/ov5647_driver_codex/scripts/run_manual_insmod_diag.sh full-delay-dump-contclk-mclk24`;
- then manually run `sudo /home/cam/ov5647_driver_codex/scripts/run_manual_single_frame_rtcpu_trace.sh`;
- report whether `insmod` succeeded, whether capture timed out, and whether the raw file size is still zero.

Update after MCLK24 manual capture:

- manual `insmod full-delay-dump-contclk-mclk24` returned `rc=0`;
- manual RTCPU/NVCSI traced capture still returned `rc=124`;
- raw output `artifacts/captures/20260422T134034Z/ov5647-640x480-bg10.raw` is zero bytes;
- trace again shows capture setup and CSI/sensor stream enable, but no SOF/EOF/NVCSI interrupt/vinotify error;
- the new MCLK logs exposed a DT clock binding bug:
  - live DT uses `clocks = <&bpmp 0x07>`;
  - Tegra234 clock binding defines `TEGRA234_CLK_AUD_MCLK = 7`;
  - Tegra234 clock binding defines `TEGRA234_CLK_EXTPERIPH1 = 36`;
  - the driver logged effective enabled MCLK `22579199 Hz`, consistent with audio MCLK, not the intended 24 MHz `extperiph1` path.

Clock-ID fix prepared:

- `patches/ov5647-p3768-port-c-probe.dts` now uses `clocks = <&bpmp 0x24>`;
- `patches/ov5647-p3768-port-a-probe.dts` was updated the same way to avoid carrying the same bug in the route-A candidate;
- built DTBO `artifacts/dtbo/20260422T134331Z-ov5647-p3768-port-c-probe.dtbo`;
- staged boot DTBO `/boot/ov5647-p3768-port-c-extperiph1.dtbo`;
- dev boot profile now uses `OVERLAYS /boot/ov5647-p3768-port-c-extperiph1.dtbo`;
- safe boot profile remains present;
- current live DT still shows old `0x07` until reboot.

Next required reboot:

- default boot profile is already `ov5647-dev`;
- safe profile remains available as `Jetson SAFE (no OV5647 auto-load)`;
- reboot is required because the DT overlay changed.

Post-reboot result after clock-ID fix:

- system booted successfully into `boot_profile=ov5647-dev`;
- safe profile remains present in `/boot/extlinux/extlinux.conf`;
- dev profile now uses `/boot/ov5647-p3768-port-c-extperiph1.dtbo`;
- live DT for `ov5647_c@36` now confirms `clocks = <&bpmp 0x24>`;
- `nv_ov5647` is not auto-loaded after reboot;
- `/dev/video0` is absent before manual module load, as expected;
- next step is manual `insmod full-delay-dump-contclk-mclk24` only, to confirm effective MCLK rate before capture.

Manual insmod after clock-ID fix:

- manual `insmod full-delay-dump-contclk-mclk24` returned `rc=0`;
- driver logs now confirm the corrected clock path:
  - `ov5647_power_get: mclk get ok name=extperiph1 current_rate=51000000`;
  - `ov5647_power_on: enabling mclk def_clk_freq=24000000 current_rate=51000000`;
  - `ov5647_power_on: mclk enabled rate=24000000`;
- BPMP debugfs also reports `extperiph1 rate=24000000`;
- `aud_mclk` remains separate at `45158398`, confirming the DT binding no longer targets audio MCLK;
- `/dev/video0` is present;
- `media-ctl -p` shows the enabled route `nv_ov5647 9-0036 -> nvcsi -> vi-output`.

Next manual runtime test:

- run one RTCPU/NVCSI traced single-frame capture manually;
- if it still returns no SOF and zero bytes with MCLK fixed, the remaining leading suspects are physical CSI lane path/cable/adapter mapping or sensor module electrical compatibility.

Manual capture after confirmed extperiph1 MCLK:

- manual RTCPU/NVCSI traced capture `20260422T135523Z` returned `rc=124`;
- raw output `artifacts/captures/20260422T135523Z/ov5647-640x480-bg10.raw` is zero bytes;
- driver logs still confirm corrected active MCLK during capture:
  - `ov5647_power_on: mclk enabled rate=24000000`;
  - `ov5647_set_stream: continuous_mipi_clock=1`;
  - stream-on readback showed `0x0100=0x01` and `0x4800=0x04`;
- VI still logged repeated `uncorr_err: request timed out after 2500 ms`;
- RTCPU trace again shows channel setup and stream enable, but no runtime `vi_frame_begin`, `vi_frame_end`, `rtcpu_nvcsi_intr`, `rtcpu_vinotify_error`, or capture SOF/error events.

Current interpretation:

- the wrong BPMP clock ID was a real bug and is fixed for route C;
- the no-SOF failure remains after the sensor is clocked at 24 MHz;
- because the earlier route-A tests were also performed before the clock-ID fix, route A is not fully ruled out yet;
- the next controlled DT-only software experiment is route A with the corrected `TEGRA234_CLK_EXTPERIPH1` clock binding;
- if route A with corrected MCLK also has no SOF, the highest-probability cause becomes physical CLB/makerobo connector routing, FFC/adaptor pinout/orientation, or Raspberry Pi-style OV5647 electrical compatibility.

Route-A corrected-MCLK boot staged:

- built route-A DTBO from `patches/ov5647-p3768-port-a-probe.dts`;
- artifact: `artifacts/dtbo/20260422T135929Z-ov5647-p3768-port-a-probe.dtbo`;
- installed boot overlay: `/boot/ov5647-p3768-port-a-extperiph1.dtbo`;
- checksum matches between artifact and `/boot` copy;
- `/boot/extlinux/extlinux.conf` now has:
  - `DEFAULT ov5647-dev`;
  - safe entry `ov5647-safe` with `boot_profile=ov5647-safe`;
  - dev entry `ov5647-dev` with `OVERLAYS /boot/ov5647-p3768-port-a-extperiph1.dtbo`;
- DTBO decompile confirms route-A fields:
  - `i2c@0`;
  - `ov5647_a@36`;
  - `clocks = <... 0x24>`;
  - `tegra_sinterface = "serial_b"`;
  - `port-index = <1>`;
  - `lane_polarity = "6"`;
  - `pwdn-gpios = <... 0x3e 0>`.

Next required reboot:

- reboot is required because the overlay changed;
- the default boot profile is already `ov5647-dev`;
- safe boot remains available as `Jetson SAFE (no OV5647 auto-load)`;
- after reboot, first verify `/proc/cmdline` and live DT before any module or capture command.

Post-reboot result for route-A corrected-MCLK overlay:

- system booted into `boot_profile=ov5647-dev`;
- `/boot/extlinux/extlinux.conf` still contains both safe and dev profiles;
- dev profile points to `/boot/ov5647-p3768-port-a-extperiph1.dtbo`;
- `nv_ov5647` is not auto-loaded;
- `/dev/video0` and `/dev/v4l-subdev*` are absent before manual module load, as expected;
- live DT now contains route-A node:
  - `/sys/firmware/devicetree/base/bus@0/cam_i2cmux/i2c@0/ov5647_a@36`;
  - `status = "okay"`;
  - `compatible = "ovti,ov5647"`;
  - `mclk = "extperiph1"`;
  - `clocks_hex = 00 00 00 03 00 00 00 24`;
  - `pwdn-gpios = <... 0x3e 0>`;
  - `mode0.tegra_sinterface = "serial_b"`;
  - `mode0.lane_polarity = "6"`;
  - endpoint `port-index = 1`;
  - endpoint `bus-width = 2`;
- route-C `ov5647_c@36` node is absent;
- `media-ctl -p` currently shows only the base `nvcsi` entity with no sensor link before module load;
- pstore contains `console-ramoops-0` from the previous boot, including the earlier route-C capture timeout and a normal `reboot: Restarting system` tail; no panic/oops/NULL dereference signature was found in that pstore scan.

Next manual test:

- run only manual route-A insmod diagnostics first;
- do not run capture until route-A probe/chip-ID/MCLK are confirmed after this reboot.

Manual route-A insmod after corrected-MCLK reboot:

- user ran `sudo /home/cam/ov5647_driver_codex/scripts/run_manual_insmod_diag.sh full-delay-dump-contclk-mclk24`;
- command returned `insmod rc=0`;
- module parameters:
  - `register_i2c_driver=Y`;
  - `allow_hw_probe=Y`;
  - `dump_stream_regs=Y`;
  - `continuous_mipi_clock=Y`;
  - `mclk_override_hz=24000000`;
- probe path:
  - `ov5647_parse_dt`: `mclk=extperiph1`, `reset_gpio=-1`, `pwdn_gpio=397`;
  - supplies are dummy regulators for `vana`, `vdig`, `vif`;
  - `ov5647_power_on`: enabled MCLK at `24000000`;
  - `ov5647_board_setup`: detected `chip_id=0x5647`;
  - V4L2 registration succeeded;
- active BPMP clocks after probe:
  - `extperiph1 = 24000000`;
  - `aud_mclk = 45158398`;
- media graph after probe:
  - `nv_ov5647 9-0036` sensor entity exists;
  - `/dev/video0` exists as `vi-output, nv_ov5647 9-0036`;
  - sensor -> nvcsi -> vi links are enabled;
- `v4l2-ctl --all` shows:
  - format `BG10`;
  - `640x480`;
  - `Size Image = 614400`;
  - `30 fps`;
  - `sensor_modes = 1`.

Next manual runtime test:

- run the RTCPU/NVCSI traced single-frame capture on this route-A corrected-MCLK setup;
- if this still gives `rc=124`, zero bytes, and no SOF, both route A and route C will have failed after the clock-ID fix and physical CLB/makerobo connector/cable/adaptor compatibility becomes the dominant root-cause track.

Manual route-A corrected-MCLK capture result:

- user ran `sudo /home/cam/ov5647_driver_codex/scripts/run_manual_single_frame_rtcpu_trace.sh`;
- timestamp: `20260422T140936Z`;
- capture setup reached `VIDIOC_STREAMON returned 0 (Success)`;
- capture returned `rc=124`;
- raw output `artifacts/captures/20260422T140936Z/ov5647-640x480-bg10.raw` is zero bytes;
- dmesg log: `logs/20260422T140936Z-single-frame-rtcpu-live-dmesg.log`;
- RTCPU/NVCSI trace dir: `artifacts/traces/20260422T140936Z`;
- driver readback during stream-on remained internally consistent:
  - MCLK enabled at `24000000`;
  - `0x0100 = 0x01`;
  - output-enable registers restored: `0x3000 = 0x0f`, `0x3001 = 0xff`, `0x3002 = 0xe4`;
  - continuous-clock diagnostic value active: `0x4800 = 0x04`;
- VI logged repeated `uncorr_err: request timed out after 2500 ms`;
- trace events were enabled, but the trace contained no runtime `vi_frame_begin`, `vi_frame_end`, `rtcpu_nvcsi_intr`, `rtcpu_vinotify_error`, `capture_event_sof`, `capture_event_eof`, or `capture_event_error`.

Current interpretation after route-A and route-C corrected-MCLK tests:

- the original wrong BPMP clock-ID binding was a real bug and is fixed;
- output-enable, duplicate set-mode, LP-11 setup, HTS/VTS, and continuous-clock experiments did not produce SOF;
- route A and route C both probe and both fail to deliver any observable CSI SOF after corrected 24 MHz `extperiph1` MCLK;
- the highest-probability blocker is now the physical CLB/makerobo camera path: exact connector route, FFC/adaptor pinout/orientation, Raspberry Pi-style `JT-ZERO-V2.0 YH` module compatibility, or lane wiring/polarity not represented by the NVIDIA p3768 reference overlays.

Next smallest safe step:

- do not run more blind stream-register tuning or repeated captures until the physical CSI path is verified;
- collect physical evidence for both camera connectors: carrier silkscreen labels, cable orientation, contact side, any adapter board, camera module front/back, and the full FFC marking;
- if available, test a known-good Jetson-compatible camera/cable kit with a stock NVIDIA overlay to prove the CLB CSI connector path independently of this OV5647 driver.

Update after user confirmed Raspberry Pi Zero 22-pin cameras:

- user confirms the cameras are Raspberry Pi Zero-style 22-pin OV5647 modules;
- this makes the cable family more specific, but does not by itself prove MIPI lane delivery because I2C success can coexist with a CSI lane mismatch;
- a source-side timing/register variant was found in the current 640x480 mode table:
  - mainline upstream Linux OV5647 VGA table uses `0x3821 = 0x03`;
  - Raspberry Pi downstream 6.6.y OV5647 VGA table uses `0x3821 = 0x01`;
  - the local driver previously matched the Raspberry Pi downstream value;
- next safe software step is to test the mainline upstream `0x3821 = 0x03` variant as a single controlled variable, rebuild only, and ask the user to perform one manual load/capture cycle.
