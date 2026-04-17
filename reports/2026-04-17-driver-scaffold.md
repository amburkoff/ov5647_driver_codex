# 2026-04-17 OV5647 Driver Scaffold Checkpoint

## What Changed

- pushed checkpoint commit `8572879` to `origin/main`;
- replaced the trivial `nv_ov5647` module stub with a gated OV5647 driver scaffold;
- updated the external module build to include:
  - NVIDIA `nvidia-oot` media headers
  - NVIDIA `nvidia-oot/Module.symvers`
- revalidated external module build against the installed Jetson camera framework.

## Files Changed

- `src/nv_ov5647/Makefile`
- `src/nv_ov5647/nv_ov5647.c`
- `README.md`
- `docs/04-driver-architecture.md`
- `docs/06-build-and-install.md`
- `docs/10-results-and-status.md`

## Commands Run

- source and symbol inspection:
  - `sed -n ... /usr/src/nvidia/nvidia-oot/include/media/*.h`
  - `grep ... /usr/src/nvidia/nvidia-oot/Module.symvers`
  - `grep ... /lib/modules/$(uname -r)/modules.symbols`
- git sync:
  - `git push origin main`
- build validation:
  - `./scripts/build_module.sh`
  - repeated after `Makefile` fixes for include path and `KBUILD_EXTRA_SYMBOLS`

## Logs Saved

- `logs/20260417T105209Z-build_module.log`
- `logs/20260417T105224Z-build_module.log`
- `logs/20260417T105242Z-build_module.log`
- `artifacts/build/20260417T105242Z/nv_ov5647.ko`
- `artifacts/build/20260417T105242Z/nv_ov5647.modinfo.txt`

## Tests Passed

- `git push origin main` completed successfully;
- new `nv_ov5647` driver scaffold built successfully as an external module;
- resulting module metadata is correct:
  - depends on `tegra-camera`
  - exports `of:ovti,ov5647` and `i2c:ov5647` aliases
  - exposes safety parameters:
    - `register_i2c_driver`
    - `allow_hw_probe`

## Tests Failed Or Blocked

- first build failed because the external module did not yet include NVIDIA `nvidia-oot` header paths;
- second build failed at `modpost` because `tegra-camera` exported symbols were not yet supplied via `KBUILD_EXTRA_SYMBOLS`;
- runtime `insmod`/`rmmod` validation is currently blocked because `sudo` on this machine requires an interactive password and the agent cannot provide it.

## Findings

- the local system provides all required Jetson camera framework headers under `/usr/src/nvidia/nvidia-oot/include/media/`;
- the local system also provides the exact exported symbol map needed for external sensor modules under `/usr/src/nvidia/nvidia-oot/Module.symvers`;
- the driver scaffold can therefore be developed and build-validated locally without first downloading full BSP sensor sources.

## Current Root-Cause Hypotheses

- the main blocker for first real probe is still carrier-specific hardware mapping, not missing framework code;
- the next safe runtime milestone is a root-verified module lifecycle check with the default safety gate still active;
- only after that should the project attempt the first explicit `register_i2c_driver=1 allow_hw_probe=1` probe on a verified DT path.

## Next Smallest Step

1. Verify `insmod` and `rmmod` of the gated scaffold using local root access.
2. Confirm the physical CBL connector and adapter path.
3. Draft the first minimal OV5647 overlay for the verified connector only.
4. Attempt the first controlled chip-ID probe.

## Reboot

- reboot required now: `no`
- default boot profile changed: `no`

