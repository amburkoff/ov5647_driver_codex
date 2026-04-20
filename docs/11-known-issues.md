# Known Issues

- The user target is described as a CBL Developer Kit carrier, but the running DT identifies NVIDIA reference carrier `p3768-0000`.
- The running system currently boots with `boot_profile=ov5647-dev`, while the carrier hardware still needs independent CBL-specific documentation beyond what the base DT exposes.
- The safe boot entry still exists, but the on-disk default is currently set to `ov5647-dev` for the next controlled overlay-validation reboot cycle.
- The active dev overlay is still an assumption-driven route-A candidate and has only been validated far enough to create the muxed I2C path and sensor DT node.
- `/dev/media0` is present, but no `/dev/video*` node exists yet.
- The physical camera modules are present on both 22-pin connectors, but the exact mapping from physical connector to route `A` or `C` is still unverified.
- The visible camera marking `JT-ZERO-V2.0 YH` suggests Raspberry Pi-market OV5647 hardware, but the exact FFC/adaptor topology is not yet documented.
- `v4l2-ctl`, `media-ctl`, and `v4l2-compliance` are not installed at this checkpoint.
- Local `nvidia-oot` headers are present, but full local sample sensor source files are not installed under `/usr/src/nvidia/`.
- Unprivileged `dmesg` access is restricted, so full kernel-buffer capture requires elevated privileges.
- `journalctl --list-boots` and `uptime -s` disagree about the current boot start time, so timestamp interpretation needs care.
- The draft route-A OV5647 overlay compiles locally, but it still relies on unresolved hardware assumptions and keeps the sensor node disabled.
- The probe-oriented route-A OV5647 overlay now applies at boot and probes far enough to request regulators and clock resources, but it still relies on unresolved hardware assumptions.
- The first rebooted dev attempt proved that `FDTOVERLAYS` was not the correct overlay mechanism for this UEFI-based boot path; the corrected path now uses `FDT + OVERLAYS`.
- A previous manual `insmod` of `nv_ov5647` triggered a kernel panic due to `tegracam_set_privdata()` being called too early; that ordering bug is fixed, but the panic history remains relevant for regression checking.
- The current first-order runtime blocker is `ov5647_power_get(): mclk get failed err=-2`, which indicates the active live DT still lacks a usable clock binding for the sensor node.
- `i2cdetect -y 9` still does not show a visible responder at `0x36`, so the hardware route, power state, or sensor identity is not yet confirmed from the bus level.
