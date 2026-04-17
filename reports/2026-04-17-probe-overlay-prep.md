# 2026-04-17 Probe Overlay Preparation

## What Changed

- added a reusable overlay build script:
  - `scripts/build_overlay.sh`
- kept the existing route-A overlay draft for disabled-node validation;
- added a separate route-A probe-oriented overlay candidate with:
  - one sensor
  - one CSI route
  - `status = "okay"` on the sensor node
  - one minimal 640x480 mode
- compiled both overlay variants into `.dtbo` artifacts without applying them.

## Files Changed

- `scripts/build_overlay.sh`
- `patches/ov5647-p3768-port-a-probe.dts`
- `docs/05-dt-overlay-design.md`

## Commands Run

- `chmod +x scripts/build_overlay.sh`
- `./scripts/build_overlay.sh patches/ov5647-p3768-port-a-draft.dts`
- `./scripts/build_overlay.sh patches/ov5647-p3768-port-a-probe.dts`

## Logs Saved

- `logs/20260417T124626Z-build_overlay-ov5647-p3768-port-a-draft.log`
- `logs/20260417T124633Z-build_overlay-ov5647-p3768-port-a-probe.log`

## Artifacts Saved

- `artifacts/dtbo/20260417T124626Z-ov5647-p3768-port-a-draft.dtbo`
- `artifacts/dtbo/20260417T124633Z-ov5647-p3768-port-a-probe.dtbo`

## Tests Passed

- reusable overlay build script works;
- route-A disabled draft overlay compiles;
- route-A probe-oriented overlay compiles;
- no boot config change was made in this checkpoint;
- no overlay was applied;
- no reboot was required.

## Tests Failed

- the first attempt to build the probe overlay failed with `Permission denied` because it raced the `chmod +x` step in a parallel command block.

## Root-Cause Hypothesis For The Failed Attempt

- the script itself was valid;
- the failure came from execution order, not from overlay syntax or DT content.

## Findings

- the repository now has a clear split between:
  - a disabled local-validation overlay draft;
  - an enabled probe-oriented overlay candidate for a future one-port experiment;
- both current route-A overlays still depend on unresolved route-A hardware assumptions and must not be treated as carrier-verified;
- expected `dtc` warnings remain limited to common overlay structural warnings and did not block output generation.

## Next Smallest Step

1. Decide how the first enabled route-A overlay will be introduced for testing:
   - `FDTOVERLAYS` in the dev boot entry, or
   - another validated mechanism if one becomes available.
2. Keep the safe profile as default until that exact probe experiment is ready.
3. Pair the first enabled overlay test with a single controlled `allow_hw_probe=1` driver run.

## Reboot Needed

- No.
