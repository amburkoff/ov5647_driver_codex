# 2026-04-22 RTCPU Trace No SOF

## Summary

The manual RTCPU/NVCSI traced capture still timed out. The trace did not show any frame start or NVCSI error event.

Result: current evidence is now stronger for no CSI signal/SOF reaching NVCSI/VI.

## User-Run Command

```bash
sudo /home/cam/ov5647_driver_codex/scripts/run_manual_single_frame_rtcpu_trace.sh
```

## Capture Result

```text
VIDIOC_STREAMON returned 0 (Success)
capture rc=124
raw size=0 bytes
```

Raw artifact:

- `artifacts/captures/20260422T085920Z/ov5647-640x480-bg10.raw`

Trace artifacts:

- `artifacts/traces/20260422T085920Z/`

## Trace Evidence

Events that appeared:

- sensor power on through `camera_common_s_power`;
- CSI power on through `csi_s_power`;
- `tegra_channel_capture_setup`;
- four VI task submits;
- `csi_s_stream: enable : 0x1`;
- `tegra_channel_set_stream: nv_ov5647 9-0036 : 0x1`;
- stop/power-down events after timeout.

Events that did not appear:

- `vi_frame_begin`;
- `vi_frame_end`;
- `rtcpu_vinotify_error`;
- `rtcpu_nvcsi_intr`;
- `capture_event_sof`;
- `capture_event_eof`;
- `capture_event_error`;
- `capture_event_wdt`;
- `tegra_channel_capture_frame`;
- `tegra_channel_capture_done`.

RTCPU debugfs:

```text
last_exception: empty
stats: Exceptions: 0, Events: 3
last_event: Start
```

## Interpretation

The trace does not look like a stream with bad frames. It looks like no SOF reaches the VI/NVCSI capture path during the 30 second window.

Most likely next areas:

- physical FFC/cable/adapter compatibility for the Raspberry Pi-style `JT-ZERO-V2.0 YH` modules;
- actual CLB connector to Jetson CSI route mapping;
- lane polarity or lane order;
- sensor MIPI output not actually present despite successful I2C/chip-ID;
- wrong assumptions in carrier-specific wiring, not just a missing V4L2 registration step.

## Next Best Step

Do not keep changing sensor stream bits blindly.

The next controlled experiment should be a hardware-route validation step:

- document exactly which camera connector is tested;
- confirm FFC orientation and adapter type;
- if a known-good Jetson-compatible IMX219/IMX477 module is available, test the same physical connector with NVIDIA's reference overlay;
- otherwise prepare one lane-polarity/route experiment at a time and use the RTCPU trace as the acceptance signal.

## Logs

- `logs/20260422T085920Z-single-frame-rtcpu-trace.log`
- `logs/20260422T085920Z-single-frame-rtcpu-live-dmesg.log`
- `logs/20260422T085920Z-single-frame-rtcpu-post-dmesg-tail.log`
- `logs/20260422T090018Z-list-085920-rtcpu-trace-files.log`
- `logs/20260422T090018Z-inspect-085920-run-log-and-trace-sizes.log`
- `logs/20260422T090018Z-inspect-085920-trace-config.log`
- `logs/20260422T090018Z-grep-085920-rtcpu-events.log`
- `logs/20260422T090034Z-cat-085920-after-trace.log`
- `logs/20260422T090034Z-grep-085920-final-trace.log`
- `logs/20260422T090034Z-cat-085920-pre-capture-state.log`
- `logs/20260422T090034Z-grep-085920-dmesg.log`
- `logs/20260422T090056Z-confirm-085920-no-sof-error-events.log`
- `logs/20260422T090056Z-summarize-085920-trace-event-types.log`
- `logs/20260422T090056Z-dmesg-slice-085920-capture.log`
- `logs/20260422T090056Z-stat-085920-raw-trace.log`
