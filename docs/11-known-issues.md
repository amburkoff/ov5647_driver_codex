# Known Issues

- The user target is described as a CBL Developer Kit carrier, but the running DT identifies NVIDIA reference carrier `p3768-0000`.
- The active boot configuration has only one `primary` label and no `boot_profile=*` marker.
- No camera sensor overlay is active on the running system.
- No `/dev/video*` or `/dev/media*` nodes are present yet.
- The physical camera modules are present on both 22-pin connectors, but the exact mapping from physical connector to route `A` or `C` is still unverified.
- The visible camera marking `JT-ZERO-V2.0 YH` suggests Raspberry Pi-market OV5647 hardware, but the exact FFC/adaptor topology is not yet documented.
- `v4l2-ctl`, `media-ctl`, and `v4l2-compliance` are not installed at this checkpoint.
- Local `nvidia-oot` headers are present, but full local sample sensor source files are not installed under `/usr/src/nvidia/`.
- Unprivileged `dmesg` access is restricted, so full kernel-buffer capture requires elevated privileges.
- `journalctl --list-boots` and `uptime -s` disagree about the current boot start time, so timestamp interpretation needs care.
- The draft route-A OV5647 overlay compiles locally, but it still relies on unresolved hardware assumptions and keeps the sensor node disabled.
