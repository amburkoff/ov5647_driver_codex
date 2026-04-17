# Hardware Assumptions And Risks

Current blocking assumption set:

- The project target is described by the user as a CBL Developer Kit carrier.
- The running software image still identifies the platform as NVIDIA `p3768-0000+p3767-0000`.
- No active camera overlay on the running system currently proves how the OV5647 is wired.

Assumptions that are intentionally not promoted to facts:

- the physical camera connector is `A`;
- the physical camera connector is `C`;
- the OV5647 uses the standard Raspberry Pi V1 pinout end to end without any carrier adaptation;
- the sensor address is already known;
- the reset and power-down GPIOs match NVIDIA IMX219 or IMX477 examples;
- the carrier reuses the exact devkit `cam_i2cmux` topology.

Risk register:

| Risk | Impact | Current mitigation |
| --- | --- | --- |
| Wrong carrier identity in DT or docs | Incorrect overlay and GPIO routing | Use live DT and physical inspection before enabling sensor nodes |
| Wrong CSI connector assumption | No image or unstable stream | Do not enable boot-time overlay until connector mapping is confirmed |
| Wrong I2C bus or address | Probe failure or false debugging path | Keep first probe manual and log every I2C-related assumption |
| Wrong reset or PWDN GPIO | Sensor never responds or enters undefined state | Implement power logic only after GPIO source is verified |
| Wrong regulator mapping | Unsafe power-up sequence | Keep regulator names unresolved until verified |
| Missing tool dependencies | Incomplete validation | Document missing `v4l-utils` and `media-ctl` early |

