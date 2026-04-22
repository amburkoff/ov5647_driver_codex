# OV5647 Driver Bring-Up For Jetson Orin NX

This repository is the working area for a clean-room OV5647 MIPI CSI-2 bring-up on Jetson Orin NX with Jetson Linux `r36.5` and JetPack `6.2.2`. The immediate goal is to establish a safe, reproducible development loop before any risky probe or boot-time integration is attempted.

Current checkpoint:

- safe/dev boot profiles are active; the current boot is `boot_profile=ov5647-dev`;
- the dev boot profile applies the route-C continuous-clock overlay `/boot/ov5647-p3768-port-c-contclk.dtbo`;
- live DT confirms `ov5647_c@36`, `serial_c`, `port-index = <2>`, `bus-width = <2>`, `lane_polarity = "0"`, and `discontinuous_clk = "no"`;
- manual route-A and route-C probes have both read OV5647 chip ID `0x5647`;
- module load/unload is no longer blocked by the earlier remove-path crash after fixing the I2C clientdata misuse;
- route-C manual streaming reaches `VIDIOC_STREAMON`, but no CSI frames are delivered yet.

Current blockers:

- the physical kit is now corrected to `CLB Developer Kit`; earlier project notes used a mistyped carrier name;
- the box identifies the board as a `makerobo` partner board;
- the included booklet says to install the official Jetson Developer Kit image, so the live `p3768` DT identity is expected but still not proof of the exact CLB camera wiring;
- physical CLB connector to DT route mapping is still not independently verified;
- the Raspberry Pi-style camera/cable path marked `JT-ZERO-V2.0 YH` may not be CSI-compatible with the current CLB/Jetson 22-pin route;
- route-A and route-C both create `/dev/video0` after manual LKM load, but raw captures still time out with zero-byte files;
- live preview is not validated.

Start here:

- [docs/00-project-scope.md](docs/00-project-scope.md)
- [docs/01-platform-inventory.md](docs/01-platform-inventory.md)
- [docs/01a-clb-carrier-mapping.md](docs/01a-clb-carrier-mapping.md)
- [docs/03-sources-and-references.md](docs/03-sources-and-references.md)
- [docs/09-boot-profiles-and-recovery.md](docs/09-boot-profiles-and-recovery.md)

Useful scripts:

- `scripts/collect_env.sh`
- `scripts/collect_camera_route_state.sh`
- `scripts/capture_kernel_logs.sh`
- `scripts/build_module.sh`
- `scripts/switch_boot_profile.sh`
- `scripts/install_module.sh`
- `scripts/unload_module.sh`

The project is not considered successful until:

- safe and dev boot profiles both exist and are recoverable;
- manual module load and unload are stable;
- one confirmed OV5647 instance probes safely on one verified 2-lane CSI port;
- raw capture works;
- a visible image is displayed from the camera.
