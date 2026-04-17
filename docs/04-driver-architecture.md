# Driver Architecture

Planned driver shape:

- module name: `nv_ov5647`
- target framework: Jetson V4L2 Camera Framework on Jetson Linux `r36.5`
- development mode: loadable kernel module first
- first runtime scope: one sensor instance, one mode, direct V4L2 RAW path
- current safety gate:
  - `register_i2c_driver=0` by default
  - `allow_hw_probe=0` by default

Planned implementation layers:

1. `i2c_driver` registration and safe probe or remove.
2. DT parsing for clocks, regulators, GPIOs, CSI route, and mode metadata.
3. Power-on and power-off with symmetric unwind.
4. Chip-ID read before mode or control setup.
5. Minimal control set needed for stable RAW streaming.
6. One validated mode table.
7. Stream on and off with detailed logs.

Logging policy inside the driver:

- entry or exit breadcrumbs for probe, remove, power, reset, DT parse, chip-ID, mode apply, and stream transitions;
- explicit return codes on failures;
- no silent fallback between alternate GPIO or supply names.

Current repository state:

- `src/nv_ov5647/nv_ov5647.c` is now a Jetson-style OV5647 driver scaffold;
- it contains:
  - `tegracam` device plumbing
  - `camera_common` power and DT hooks
  - regmap read or write wrappers
  - chip-ID board-setup path
  - explicit logging on probe, DT parse, power, and chip-ID operations
- by default the module still does not register its i2c driver on load;
- even if the i2c driver is registered later, probe is blocked unless `allow_hw_probe=1` is set explicitly.
