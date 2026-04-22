# Raspberry Pi Zero Camera Fact And VGA 0x3821 Diagnostic

Date: 2026-04-22

## New Hardware Fact

The user confirmed that the installed OV5647 modules are Raspberry Pi Zero-style cameras with 22-pin connectors.

This narrows the hardware model, but it does not prove CSI frame delivery. I2C chip ID can succeed while MIPI clock/data lanes still fail to produce SOF at NVCSI/VI.

## Source Finding

The current local 640x480 mode table differs from mainline upstream Linux OV5647 VGA mode:

- mainline upstream Linux: `0x3821 = 0x03`;
- Raspberry Pi downstream 6.6.y: `0x3821 = 0x01`;
- local driver before this change: `0x3821 = 0x01`.

This is not proof of root cause because the Raspberry Pi downstream branch matches the old local value. It is still a controlled single-register diagnostic against the only active mode and should be tested before making more invasive changes.

## Change

Updated `src/nv_ov5647/nv_ov5647.c` so the active 640x480 mode can test the mainline upstream value:

```c
{0x3821, 0x03},
```

## Next Test

Build only from Codex. Runtime load/capture remains manual:

```bash
sudo /home/cam/ov5647_driver_codex/scripts/run_manual_insmod_diag.sh full-delay-dump-contclk-mclk24
sudo /home/cam/ov5647_driver_codex/scripts/run_manual_single_frame_rtcpu_trace.sh
```

If the module is already loaded, unload/reboot handling must be decided manually by the user to preserve Codex CLI context if the Jetson hangs.
