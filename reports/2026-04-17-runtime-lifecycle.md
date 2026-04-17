# 2026-04-17 Runtime Lifecycle Checkpoint

## What Changed

- validated root runtime lifecycle for the gated `nv_ov5647` module;
- validated repeated `insmod` or `rmmod` without i2c driver registration;
- validated explicit `i2c_add_driver` or `i2c_del_driver` path without allowing hardware probe;
- updated status documents with the passed runtime milestone.

## Files Changed

- `README.md`
- `docs/06-build-and-install.md`
- `docs/10-results-and-status.md`

## Commands Run

- single lifecycle:
  - `sudo ./scripts/install_module.sh ./src/nv_ov5647/nv_ov5647.ko`
  - `sudo ./scripts/unload_module.sh`
- stress loop:
  - 10 sequential install or unload cycles via `scripts/install_module.sh` and `scripts/unload_module.sh`
- i2c driver registration check:
  - `sudo insmod ./src/nv_ov5647/nv_ov5647.ko register_i2c_driver=1 allow_hw_probe=0`
  - `sudo rmmod nv_ov5647`
- evidence capture:
  - `sudo dmesg | grep nv_ov5647`
  - `lsmod | grep '^nv_ov5647'`

## Logs Saved

- single lifecycle:
  - `logs/20260417T113413Z-install_module.log`
  - `logs/20260417T113413Z-install_module.dmesg-tail.log`
  - `logs/20260417T113430Z-unload_module.log`
  - `logs/20260417T113442Z-unload_module.dmesg-tail.log`
- stress loop:
  - `logs/20260417T113440Z-module-lifecycle-loop.log`
- i2c driver registration:
  - `logs/20260417T113514Z-i2c-driver-registration-check.log`

## Tests Passed

- plain gated module load passed;
- plain gated module unload passed;
- 10 of 10 sequential install or unload cycles passed;
- final `lsmod` confirmed the module was unloaded after the stress test;
- explicit `i2c` driver registration passed with:
  - `register_i2c_driver=1`
  - `allow_hw_probe=0`
- explicit `i2c` driver unregistration passed.

## Tests Failed Or Blocked

- no real OV5647 probe was attempted, by design;
- chip-ID read is still blocked by missing verified DT or carrier mapping;
- V4L2 userspace validation remains blocked by missing `v4l-utils` tools.

## Findings

- default safe path is stable:
  - `module init register_i2c_driver=0 allow_hw_probe=0`
  - `safety gate active; i2c driver registration skipped`
  - `module exit without i2c driver registration`
- registered-driver safe path is also stable:
  - `module init register_i2c_driver=1 allow_hw_probe=0`
  - `i2c driver registered`
  - `i2c driver unregistered`
- no hangs, warnings, or partial-unload symptoms attributable to `nv_ov5647` were observed in these lifecycle checks.
- the module taints the kernel because it is unsigned:
  - `module verification failed: signature and/or required key missing`
  This is expected for the current external development module and is not itself a functional failure.

## Current Root-Cause Hypotheses

- the module lifecycle foundation is now strong enough to move to the first controlled DT-backed probe;
- the real blocker has shifted fully to carrier-specific hardware mapping and DT route confirmation.

## Next Smallest Step

1. Confirm the physical carrier identity and exact camera connector path.
2. Draft the first minimal OV5647 overlay for that verified path only.
3. Enable one OV5647 DT node.
4. Perform the first controlled chip-ID probe with `allow_hw_probe=1`.

## Reboot

- reboot required now: `no`
- default boot profile changed: `no`
