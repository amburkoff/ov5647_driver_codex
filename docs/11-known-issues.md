# Known Issues

- The user target is described as a CBL Developer Kit carrier, but the running DT identifies NVIDIA reference carrier `p3768-0000`.
- The on-disk boot configuration now has safe/dev entries, but the current running kernel session still has no `boot_profile=*` token because it predates the boot-profile update.
- No camera sensor overlay is active on the running system.
- No `/dev/video*` or `/dev/media*` nodes are present yet.
- The physical camera modules are present on both 22-pin connectors, but the exact mapping from physical connector to route `A` or `C` is still unverified.
- The visible camera marking `JT-ZERO-V2.0 YH` suggests Raspberry Pi-market OV5647 hardware, but the exact FFC/adaptor topology is not yet documented.
- `v4l2-ctl`, `media-ctl`, and `v4l2-compliance` are not installed at this checkpoint.
- Local `nvidia-oot` headers are present, but full local sample sensor source files are not installed under `/usr/src/nvidia/`.
- Unprivileged `dmesg` access is restricted, so full kernel-buffer capture requires elevated privileges.
- `journalctl --list-boots` and `uptime -s` disagree about the current boot start time, so timestamp interpretation needs care.
- The draft route-A OV5647 overlay compiles locally, but it still relies on unresolved hardware assumptions and keeps the sensor node disabled.
- The probe-oriented route-A OV5647 overlay also compiles locally, but it remains an assumption-driven candidate and has not yet been applied or probed on hardware.
- The first rebooted dev attempt proved that `FDTOVERLAYS` was not the correct overlay mechanism for this UEFI-based boot path; the corrected path now uses `FDT + OVERLAYS`.
