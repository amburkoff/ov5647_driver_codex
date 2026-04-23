# Physical CSI Validation Checklist

Status: `blocking before more blind stream experiments`

Both route A and route C now probe OV5647, create `/dev/video0`, and reach `VIDIOC_STREAMON`, but neither route produces SOF at NVCSI/VI. The next useful work is to verify the physical CSI path.

## Safety Rules

- Do not hot-plug CSI cables.
- Power the Jetson fully off before changing camera cables.
- Do not run repeated capture tests until the cable/adaptor path is documented.
- Keep the safe boot entry available.

## Photos Or Facts Needed

Capture these before changing anything:

- full top-side photo of the CLB carrier showing both CSI connectors and their silkscreen labels;
- close-up of the connector currently treated as route A, including flex orientation and visible contact side;
- close-up of the connector currently treated as route C, including flex orientation and visible contact side;
- front and back of each OV5647 module;
- full FFC marking on each cable, including `JT-ZERO-V2.0 YH` and any other printed text;
- whether there is any inline 15-pin-to-22-pin or 22-pin-to-22-pin adapter board;
- if the FFC is direct 22-pin-to-22-pin, whether contacts are same-side or opposite-side from end to end.

## Facts To Confirm

- Which physical connector is silkscreened as `J20` or camera #0.
- Which physical connector is silkscreened as `J21` or camera #1.
- Whether route A (`cam_i2cmux/i2c@0`, `serial_b`, `port-index = 1`) corresponds to physical `J20`.
- Whether route C (`cam_i2cmux/i2c@1`, `serial_c`, `port-index = 2`) corresponds to physical `J21`.
- Whether the Jetson-side 22-pin cable contacts face the carrier bottom side as NVIDIA documents for the Orin Nano developer kit.
- Whether the Raspberry Pi-style OV5647 module connector expects the opposite contact orientation or a remapping cable.
- Whether the OV5647 PCB itself has a 15-pin camera connector with a `15->22` adapter cable, or a native 22-pin connector.
- Whether the current cable is a standard-to-mini camera cable rather than a generic same-pin-count FFC.
- Whether the printed `Frank-s15-v1.0` ribbon is the actual Jetson-side camera cable now under test.

## Concrete Cable Clues

- NVIDIA documents the Jetson Orin Nano/NX developer-carrier camera connectors as 22-pin, 0.5 mm pitch, bottom-contact connectors.
- NVIDIA also documents that a Raspberry Pi Camera Module v2 with a 15-pin connector requires a 15-pin-to-22-pin conversion cable on the Jetson side.
- Raspberry Pi documents its own 22-pin CSI pinout with:
  - pin 1 = `GND`
  - pins 20/21 = `SCL` / `SDA`
  - pin 22 = `3V3`
- NVIDIA documents Jetson `J20`/`J21` with:
  - pin 1 = `3.3V`
  - pins 2/3 = `CAM_I2C_SDA` / `CAM_I2C_SCL`
  - dedicated `MCLK` / `PWDN` on pins 5/6

Implication:

- a native Raspberry Pi 22-pin camera-side pinout is not automatically same-numbered compatible with the Jetson 22-pin carrier connector;
- a correct cable or adapter can still make the path valid by reversing or remapping the flex;
- therefore the exact cable type matters as much as the sensor module.

Current high-value question:

- is the OV5647 board under test a normal 15-pin Raspberry Pi camera board connected through a proper `15->22` Jetson cable, or is it a native 22-pin Raspberry Pi Zero-style path that relies on a different pinout assumption?

## Why This Is Blocking

Successful I2C chip ID only proves power, I2C, and PWDN are plausible. It does not prove that MIPI CSI clock/data lanes are connected with the correct polarity, lane order, or contact orientation.

The current no-SOF evidence is consistent with one of these physical problems:

- wrong connector-to-DT route;
- wrong FFC side/orientation;
- wrong 22-pin pinout family for a Raspberry Pi-market module;
- missing or wrong 15-pin-to-22-pin conversion cable;
- lane swap/polarity mismatch not represented by the NVIDIA p3768 reference overlays.

## Next Software Step After Physical Evidence

After the physical path is documented, choose only one next experiment:

- if route A physically matches the connected module, keep the route-A overlay and test exactly one capture;
- if route C physically matches the connected module, switch back to the route-C overlay and test exactly one capture;
- if cable orientation or pinout is suspect, correct the hardware path before running another stream test;
- if a known-good Jetson-compatible IMX219/IMX477 camera kit is available, test it with the stock NVIDIA overlay to prove the CLB CSI connector independently of the custom OV5647 driver.
