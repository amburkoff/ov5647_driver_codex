# Sources And References

## Official NVIDIA Sources

Primary documentation for this project:

- Jetson Linux `r36.5` Developer Guide:
  - <https://docs.nvidia.com/jetson/archives/r36.5/DeveloperGuide/index.html>
- Jetson Linux `r36.5` Camera Development:
  - <https://docs.nvidia.com/jetson/archives/r36.5/DeveloperGuide/SD/CameraDevelopment.html>
- Jetson Linux `r36.5` Sensor Software Driver Programming:
  - <https://docs.nvidia.com/jetson/archives/r36.5/DeveloperGuide/SD/CameraDevelopment/SensorSoftwareDriverProgramming.html>
- Jetson Linux `r36.4.3` Sensor Software Driver Programming, used as the latest accessible r36.x camera framework reference when r36.5 page content is unavailable:
  - <https://docs.nvidia.com/jetson/archives/r36.4.3/DeveloperGuide/SD/CameraDevelopment/SensorSoftwareDriverProgramming.html>
  - confirms the r36.x tegracam remove order: `tegracam_v4l2subdev_unregister()` followed by `tegracam_device_unregister()`;
  - confirms NVIDIA's intended LKM development loop for camera sensor drivers.
- Jetson Linux `r36.5` Jetson Orin Series feature reference:
  - <https://docs.nvidia.com/jetson/archives/r36.5/DeveloperGuide/SO/JetsonOrinSeries.html>
- Jetson Linux `r36.5` Kernel guide:
  - <https://docs.nvidia.com/jetson/archives/r36.5/DeveloperGuide/SD/Kernel.html>
- NVIDIA Jetson documentation archive index:
  - <https://docs.nvidia.com/jetson/archives/index.html>

JetPack note:

- The public Jetson archive currently lists JetPack `6.2` and `6.2.1`.
- The running target's apt repository exposes `nvidia-jetpack` candidate `6.2.2+b24`.
- For this repository, Jetson Linux `r36.5` is treated as the canonical BSP source of truth, with the locally installed package set used to pin exact runtime facts.

## Official Or Primary Linux Sources

- Upstream Linux `ov5647.c` reference:
  - <https://github.com/torvalds/linux/blob/master/drivers/media/i2c/ov5647.c>
- Upstream Linux `ovti,ov5647` DT binding:
  - <https://github.com/torvalds/linux/blob/master/Documentation/devicetree/bindings/media/i2c/ovti%2Cov5647.yaml>
- Linux V4L2 userspace API:
  - <https://www.kernel.org/doc/html/latest/userspace-api/media/v4l/v4l2.html>

## Local Installed References On The Target

- base DTB in use by this software image:
  - `/boot/kernel_tegra234-p3768-0000+p3767-0000-nv.dtb`
- NVIDIA reference camera overlays on disk:
  - `/boot/tegra234-p3767-camera-p3768-imx219-A.dtbo`
  - `/boot/tegra234-p3767-camera-p3768-imx219-C.dtbo`
  - `/boot/tegra234-p3767-camera-p3768-imx477-A.dtbo`
  - `/boot/tegra234-p3767-camera-p3768-imx477-C.dtbo`
- installed sensor modules:
  - `/lib/modules/5.15.185-tegra/updates/drivers/media/i2c/nv_imx219.ko`
  - `/lib/modules/5.15.185-tegra/updates/drivers/media/i2c/nv_imx477.ko`
- local tegracam headers:
  - `/usr/src/nvidia/nvidia-oot/include/media/tegracam_core.h`
  - `/usr/src/nvidia/nvidia-oot/include/media/tegracam_utils.h`

## How These References Will Be Used

- NVIDIA `nv_imx*` overlays and modules define the expected r36.5 Jetson camera framework shape.
- upstream `ov5647.c` provides sensor semantics, register behavior, power timing cues, and mode-table reference.
- local live DT and boot files override any stale assumption from reference material.
- When official r36.5 web pages are not available in the public docs archive, use the local r36.5 headers and installed BSP artifacts as runtime truth, and use the closest official r36.x NVIDIA documentation only to confirm framework patterns.
