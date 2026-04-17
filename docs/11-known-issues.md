# Known Issues

- The user target is described as a CBL Developer Kit carrier, but the running DT identifies NVIDIA reference carrier `p3768-0000`.
- The active boot configuration has only one `primary` label and no `boot_profile=*` marker.
- No camera sensor overlay is active on the running system.
- No `/dev/video*` or `/dev/media*` nodes are present yet.
- `v4l2-ctl`, `media-ctl`, and `v4l2-compliance` are not installed at this checkpoint.
- Local `nvidia-oot` headers are present, but full local sample sensor source files are not installed under `/usr/src/nvidia/`.
- Unprivileged `dmesg` access is restricted, so full kernel-buffer capture requires elevated privileges.
- `journalctl --list-boots` and `uptime -s` disagree about the current boot start time, so timestamp interpretation needs care.

