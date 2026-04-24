# Test Plan

## Phase 0: Inventory And Safety

- verify kernel, L4T, DT model, board IDs, and boot configuration;
- snapshot current `extlinux.conf`;
- confirm `boot_profile=*` token presence or absence;
- record whether any live camera overlay is active.
- when `ov5647-dev` is staged back to the canonical route-C baseline, run
  `scripts/collect_reference_baseline_state.sh` and record whether:
  - on-disk `extlinux` already points at `/boot/ov5647-p3768-port-c-reference.dtbo`;
  - live DT has or has not caught up yet after reboot.

## Phase 1: Build Infrastructure

- clean build of the external module;
- rebuild without source changes;
- verify `modinfo` output for the built module;
- verify logs are written to disk.

## Phase 2: Module Lifecycle

- manual `insmod`;
- manual `rmmod`;
- repeated load or unload cycles;
- verify no warnings, oops, or hangs.

## Phase 3: Carrier Mapping

- confirm physical connector and adapter path;
- bind that route to a live DT endpoint and I2C path;
- confirm lane count and lane polarity;
- confirm reset, PWDN, MCLK, and regulators.

## Phase 4: Sensor Bring-Up

- safe power-on;
- chip-ID read;
- clean failure when sensor is absent or miswired;
- safe power-off and remove path.

## Phase 5: Overlay And Streaming

- compile the minimal OV5647 overlay;
- validate the live DT graph after application;
- bring up one mode;
- run RAW capture and repeated stream on or off tests.

## Phase 6: Acceptance

- safe and dev boot profiles both work;
- manual module load and unload remain stable;
- raw capture works;
- visible image is shown from the sensor;
- documentation and logs are complete.
