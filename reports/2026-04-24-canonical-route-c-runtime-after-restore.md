# Canonical Route-C Runtime After Restore

Date: 2026-04-24

## Goal

Re-run one traced manual capture after returning `ov5647-dev` to the canonical
route-C reference overlay, to confirm that the blind cross-route branch did not
mask a different route-C runtime signature.

## Preconditions

- on-disk `ov5647-dev` overlay restored to
  `/boot/ov5647-p3768-port-c-reference.dtbo`
- reboot completed
- reference baseline collector `20260424T124209Z` reported full PASS for:
  - `boot_profile`
  - `extlinux_overlay`
  - live node `ov5647_c@36`
  - `serial_c`
  - `lane_polarity=0`
  - `num_lanes=2`
  - `discontinuous_clk=yes`
  - `cil_settletime=0`

## Runtime

Commands run manually:

```bash
sudo /home/cam/ov5647_driver_codex/scripts/run_manual_insmod_diag.sh full-delay-dump
sudo /home/cam/ov5647_driver_codex/scripts/run_manual_single_frame_rtcpu_trace.sh
```

Artifacts:

- trace dir: `artifacts/traces/20260424T130137Z`
- capture file: `artifacts/captures/20260424T130137Z/ov5647-640x480-bg10.raw`

## Result

- `insmod rc=0`
- `VIDIOC_STREAMON` success
- raw size `0 bytes`
- trace summary:
  - `receiver_signature=no_receiver_ingress_visible`
- timed clock/power summary:
  - `clk_pm_signature=vi_and_nvcsi_clocks_observed_during_timeout`

## Conclusion

The restored canonical route-C baseline still reproduces the same receiver-side
signature as:

- earlier route-C tests
- route-A tests
- both blind cross-route hybrids

So the blind route-permutation branch can remain closed without losing a better
known runtime baseline.
