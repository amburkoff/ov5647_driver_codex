# OV5647 Driver Bring-Up For Jetson Orin NX

This repository is the working area for a clean-room OV5647 MIPI CSI-2 bring-up on Jetson Orin NX with Jetson Linux `r36.5` and JetPack `6.2.2`. The immediate goal is to establish a safe, reproducible development loop before any risky probe or boot-time integration is attempted.

Current checkpoint:

- live platform inventory captured from the running target;
- repository scaffolding, docs, scripts, and log layout created;
- safe/dev boot profile workflow prepared as a generated `extlinux.conf` candidate, not auto-applied;
- external module build pipeline prepared with a gated `nv_ov5647` driver scaffold.

Current blockers:

- the running system identifies itself as NVIDIA reference carrier `p3768`, not yet as a verified CBL-specific carrier;
- no `boot_profile=*` token exists in the active kernel command line;
- no live camera overlay is currently applied;
- `v4l2-ctl`, `media-ctl`, and `v4l2-compliance` are not currently installed on the target;
- root-only `insmod` or `rmmod` validation from the agent is blocked by interactive `sudo` authentication on this machine.

Start here:

- [docs/00-project-scope.md](docs/00-project-scope.md)
- [docs/01-platform-inventory.md](docs/01-platform-inventory.md)
- [docs/01a-cbl-carrier-mapping.md](docs/01a-cbl-carrier-mapping.md)
- [docs/03-sources-and-references.md](docs/03-sources-and-references.md)
- [docs/09-boot-profiles-and-recovery.md](docs/09-boot-profiles-and-recovery.md)

Useful scripts:

- `scripts/collect_env.sh`
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
