# Reference Baseline Helper

Date: 2026-04-24

## Goal

Prepare one read-only helper that can verify the canonical route-C reference
baseline after a reboot without requiring manual ad-hoc command sequences.

## Added Helper

- `scripts/collect_reference_baseline_state.sh`

The helper saves artifacts under:

- `artifacts/reference-baseline-state/<timestamp>/`

It checks:

- `boot_profile`
- on-disk `extlinux` overlay path
- expected canonical live DT node
- expected route-C mode fields
- current `lsmod`, `devnodes`, `v4l2-ctl --list-devices`, `media-ctl -p`
- current `journalctl -k -b`
- current `pstore`

## Sanity Result Before Reboot

Sanity run:

- `artifacts/reference-baseline-state/20260424T123416Z`

Expected mixed result before reboot:

- `PASS boot_profile`
- `PASS extlinux_overlay`
- `FAIL live_node`
- `FAIL module1.badge`
- `FAIL module1.sysfs-device-tree`
- `FAIL mode0`

This is the correct result before reboot because:

- on-disk `ov5647-dev` already points back to
  `/boot/ov5647-p3768-port-c-reference.dtbo`
- but the currently running live DT still reflects the previously booted blind
  cross-route overlay

## Intended Use

Run this helper:

1. immediately after staging boot config changes, to prove the on-disk state;
2. again after the next reboot, to prove the live DT moved back to the
   canonical route-C baseline.
