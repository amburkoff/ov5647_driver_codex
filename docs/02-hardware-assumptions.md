# Hardware Assumptions And Risks

Current blocking assumption set:

- The project target is described by the user as a CBL Developer Kit carrier.
- The running software image still identifies the platform as NVIDIA `p3768-0000+p3767-0000`.
- The active dev boot currently applies an OV5647 route-A overlay that matches NVIDIA p3768 camera route-A conventions.
- The active route-A overlay proves a logical I2C/probe path, but it still does not prove the physical CBL connector/cable CSI lane path.

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
| Wrong CSI connector assumption | No image or unstable stream | Current route-A overlay is logically valid, but physical CBL connector mapping remains unresolved |
| Wrong I2C bus or address | Probe failure or false debugging path | Current route-A I2C path is confirmed as `i2c-9` / `0x36`, but route-C is still untested |
| Wrong reset or PWDN GPIO | Sensor never responds or enters undefined state | Implement power logic only after GPIO source is verified |
| Wrong regulator mapping | Unsafe power-up sequence | Keep regulator names unresolved until verified |
| Missing tool dependencies | Incomplete validation | Document missing `v4l-utils` and `media-ctl` early |
