# Clock ID Fix Post-Reboot - 2026-04-22

## Boot Result

- Reboot completed.
- Active command line contains `boot_profile=ov5647-dev`.
- Current `/boot/extlinux/extlinux.conf` keeps:
  - `DEFAULT ov5647-dev`;
  - `Jetson SAFE (no OV5647 auto-load)`;
  - dev overlay `/boot/ov5647-p3768-port-c-extperiph1.dtbo`.

## Live DT Verification

Active sensor node:

- `/sys/firmware/devicetree/base/bus@0/cam_i2cmux/i2c@1/ov5647_c@36`

Verified fields:

- `status = "okay"`
- `compatible = "ovti,ov5647"`
- `mclk = "extperiph1"`
- `clocks = <&bpmp 0x24>`
- `clock-names = "extperiph1"`
- `mclk_khz = "24000"`
- `tegra_sinterface = "serial_c"`
- `lane_polarity = "0"`
- `discontinuous_clk = "no"`

## Runtime State

- `nv_ov5647` is not loaded after reboot.
- `/dev/media0` exists.
- `/dev/video0` is absent before manual module load, as expected.
- `pstore` contains `console-ramoops-0`, but grep for panic/Oops/OV5647 markers did not show a new crash signature.

## Logs

- `logs/20260422T135118Z-post-reboot-clock-id-fix-basic-state.log`
- `logs/20260422T135118Z-post-reboot-clock-id-fix-live-dt.log`
- `logs/20260422T135118Z-post-reboot-clock-id-fix-pstore-dmesg.log`
- `logs/20260422T135127Z-post-reboot-clock-id-fix-collect-route-state.log`
- `artifacts/camera-route-state/20260422T135127Z/`

## Next Step

Manual-only runtime test:

```bash
sudo /home/cam/ov5647_driver_codex/scripts/run_manual_insmod_diag.sh full-delay-dump-contclk-mclk24
```

Expected diagnostic target:

- `insmod rc=0`;
- driver log should show `mclk enabled rate` near 24 MHz on the corrected `extperiph1` clock binding.

Do not run capture until the MCLK rate is confirmed from the new insmod log.
