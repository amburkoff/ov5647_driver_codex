# 2026-04-21 Route-C Boot Staged

## Summary

The route-C DTBO was staged into `/boot`, and the dev boot profile was updated to use it on the next reboot. The safe boot profile remains present and has no OV5647 overlay.

No reboot was run by Codex.

## Applied Boot State

Active `/boot/extlinux/extlinux.conf` now contains:

- `DEFAULT ov5647-dev`;
- `LABEL ov5647-safe` with `boot_profile=ov5647-safe` and no `OVERLAYS`;
- `LABEL ov5647-dev` with:
  - `boot_profile=ov5647-dev`;
  - `OVERLAYS /boot/ov5647-p3768-port-c-probe.dtbo`.

The previous extlinux config was backed up by the switch script:

- `/boot/extlinux/extlinux.conf.20260421T155602Z.bak`

## Staged DTBO

Source artifact:

- `artifacts/dtbo/20260421T155351Z-ov5647-p3768-port-c-probe.dtbo`

Boot path:

- `/boot/ov5647-p3768-port-c-probe.dtbo`

SHA256:

```text
85eed7f0b43e4ac7226759075b881e636efd898351c54fdf96f5913a768921d0
```

## Saved Artifacts

- `artifacts/boot/20260421T155602Z/extlinux.conf.current`
- `artifacts/boot/20260421T155602Z/extlinux.conf.generated`
- `artifacts/boot/20260421T155611Z-route-c-applied/extlinux.conf.active`
- `artifacts/boot/20260421T155611Z-route-c-applied/extlinux.conf.before-route-c.bak`
- `artifacts/boot/20260421T155611Z-route-c-applied/extlinux.conf.generated`

## Logs

- `logs/20260421T155602Z-apply-route-c-dev-boot-profile.log`
- `logs/20260421T155602Z-verify-route-c-dev-boot-profile.log`
- `logs/20260421T155611Z-copy-active-extlinux-route-c.log`
- `logs/20260421T155611Z-route-c-boot-artifact-list.log`

## Next Required Action

The next step requires reboot because the DT overlay is applied only at boot.

Expected next boot:

- default profile: `ov5647-dev`;
- expected cmdline marker: `boot_profile=ov5647-dev`;
- expected overlay: route C, `ov5647_c@36` under `cam_i2cmux/i2c@1`.

The user should run exactly:

```bash
sudo reboot
```

After reconnect, immediately run post-reboot collection before any module operation.
