# 2026-04-21 Next Unload Diagnostics Prep

## Context

- full V4L2-registration unload still hard-hangs the Jetson;
- `skip_v4l2_register=1` load/unload succeeds;
- userspace holders are not present:
  - `fuser` empty;
  - `lsof` empty;
  - module `refcnt=0`;
  - module holders empty.

## Change Prepared

- added `skip_v4l2_unregister`:
  - diagnostic-only module parameter;
  - skips `tegracam_v4l2subdev_unregister()` inside `remove()`;
  - intentionally documented as leak-risk diagnostic, not a production fix.
- added `unload_marker_delay_ms`:
  - optional delay after unload markers;
  - intended to give the live `dmesg -W` helper time to persist the last marker before a possible hard hang.

## Intended Use

The next risky test should not be run from Codex.

When the next module version is actually loaded, use a manual full-load command with:

- `register_i2c_driver=1`
- `allow_hw_probe=1`
- `unload_marker_delay_ms=500`

If full unload still hangs without visible markers, increase marker persistence before deeper changes.

Only after that, consider the diagnostic:

- `skip_v4l2_unregister=1`

That test is not a fix; it only checks whether the hang is inside `tegracam_v4l2subdev_unregister()` or in later framework cleanup.

## Safety Note

The current running kernel still has the previously loaded module. This code change requires a new module load before it can affect runtime behavior.
