# Project Scope

Mission:

- develop and stabilize an OV5647 camera driver for Jetson Orin NX on Jetson Linux `r36.5`;
- keep the platform bootable at every stage;
- prefer loadable-module development over reboot-heavy workflows;
- record every meaningful action in `logs/`, `artifacts/`, and `reports/`.

First-stage target:

- one OV5647 sensor;
- one verified CSI connector;
- one verified CSI port in the live device tree and media graph;
- 2-lane MIPI CSI-2;
- one minimal working mode;
- raw capture first, preview second.

Non-goals for the first milestone:

- multi-camera support;
- broad mode-table coverage;
- early Argus-first enablement;
- boot-time auto-load before manual probe and remove are proven safe.

Hard constraints:

- no boot hangs;
- no `insmod` or `rmmod` hangs;
- no silent assumptions about CLB-specific wiring;
- no undocumented experiments;
- no removal of the safe boot path.

Execution order:

1. Inventory the live target and current boot state.
2. Build logging and reporting infrastructure.
3. Add a non-risky module skeleton and build loop.
4. Verify carrier-specific camera mapping.
5. Implement power, reset, clock, and chip-ID read.
6. Add a minimal overlay.
7. Validate stable `/dev/videoX`, raw capture, and preview.

