# Hardware Assumptions And Risks

Current blocking assumption set:

- The project target is described by the user as a CLB Developer Kit carrier.
- The box identifies the board as a partner board from `makerobo`.
- The included booklet instructs installing the official Jetson Developer Kit image.
- The running software image identifies the platform as NVIDIA `p3768-0000+p3767-0000`, which is consistent with that booklet instruction but not proof of CLB camera wiring.
- The active dev boot currently applies an OV5647 route-C continuous-clock overlay.
- Route-A and route-C overlays both prove logical I2C/probe paths, but neither proves the physical CLB connector/cable CSI lane path because both still produce no CSI SOF.

Assumptions that are intentionally not promoted to facts:

- the physical camera connector is `A`;
- the physical camera connector is `C`;
- the OV5647 uses the standard Raspberry Pi V1 pinout end to end without any carrier adaptation;
- route A is physically connected to the specific OV5647 module that should deliver frames;
- the reset and power-down GPIOs match NVIDIA IMX219 or IMX477 examples;
- the carrier reuses the exact devkit `cam_i2cmux` topology beyond what the live DT currently exposes.

Risk register:

| Risk | Impact | Current mitigation |
| --- | --- | --- |
| Wrong carrier identity in DT or docs | Incorrect overlay and GPIO routing | Use live DT and physical inspection before enabling sensor nodes |
| Wrong CSI connector assumption | No image or unstable stream | Route-A and route-C are logically valid enough to probe, but physical CLB connector mapping remains unresolved |
| Wrong I2C bus or address | Probe failure or false debugging path | Current route-C I2C path is confirmed as `i2c-9` / `0x36`; route-A also probed earlier |
| Wrong reset or PWDN GPIO | Sensor never responds or enters undefined state | Implement power logic only after GPIO source is verified |
| Wrong regulator mapping | Unsafe power-up sequence | Keep regulator names unresolved until verified |
| Missing tool dependencies | Incomplete validation | Document missing `v4l-utils` and `media-ctl` early |
