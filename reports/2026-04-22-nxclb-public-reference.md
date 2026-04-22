# NXCLB Public Reference Check

Date: 2026-04-22

## What Was Checked

Searched for public CLB/makerobo carrier documentation after route A and route C both produced no-SOF capture timeouts.

## Findings

- FCC ID page `2BE7C-NXCLB` identifies the product as `Embedded development board NXCLB`.
- Applicant/manufacturer is listed as `Hunan Chuang Le Bo Intelligent Technology Co., Ltd.`.
- This provides a plausible public expansion of `CLB` as `Chuang Le Bo`.
- The FCC-hosted user manual contains `J20` and `J21` camera connector tables that match the NVIDIA developer-carrier style 22-pin CSI connector descriptions.
- NVIDIA's official Orin Nano Developer Kit guide still requires the correct 15-pin-to-22-pin conversion cable for Raspberry Pi Camera Module v2 and states that the Jetson-side 22-pin cable contacts must face the bottom side.

## Engineering Impact

The public `NXCLB` manual supports treating the CLB carrier as developer-kit-like at the connector-table level. It does not prove that the installed `JT-ZERO-V2.0 YH` OV5647 modules and FFC/adaptor orientation are electrically correct.

Because both route A and route C have now failed after corrected 24 MHz `extperiph1` MCLK, the next useful step is physical CSI path validation rather than more blind register tuning.

## Sources

- <https://fccid.io/2BE7C-NXCLB>
- <https://fccid.io/2BE7C-NXCLB/User-Manual/User-Manual-7157074.pdf>
- <https://developer.nvidia.com/embedded/learn/jetson-orin-nano-devkit-user-guide/howto.html>
