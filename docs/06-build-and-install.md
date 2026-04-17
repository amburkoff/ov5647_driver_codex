# Build And Install

## External Module Build

Build the current skeleton module:

```bash
./scripts/build_module.sh
```

What it does:

- builds `src/nv_ov5647/nv_ov5647.c` as an external kernel module against `/lib/modules/$(uname -r)/build`;
- resolves NVIDIA Jetson camera framework exports using `/usr/src/nvidia/nvidia-oot/Module.symvers`;
- writes a build log to `logs/`;
- copies generated outputs to `artifacts/build/<timestamp>/`.

## Manual Install And Remove

Install the built module manually:

```bash
sudo ./scripts/install_module.sh
```

Unload it manually:

```bash
sudo ./scripts/unload_module.sh
```

Current safety properties:

- the module has `of:i2c` aliases for `ovti,ov5647`, but does not register the i2c driver unless loaded with `register_i2c_driver=1`;
- the probe path itself is blocked unless loaded with `allow_hw_probe=1`;
- no boot-time auto-load path;
- no verified mode table yet, so `set_mode` and `start_streaming` still fail fast with explicit logs.

This is deliberate. The first objective is to validate a clean LKM build and lifecycle loop before touching hardware.

## Runtime Validation Completed

Validated on the target:

- `sudo ./scripts/install_module.sh ./src/nv_ov5647/nv_ov5647.ko`
- `sudo ./scripts/unload_module.sh`
- 10 sequential install or unload cycles with the default safety gate active
- one explicit `insmod` with:

```bash
sudo insmod ./src/nv_ov5647/nv_ov5647.ko register_i2c_driver=1 allow_hw_probe=0
sudo rmmod nv_ov5647
```

Observed result:

- module loads cleanly;
- module unloads cleanly;
- i2c driver registers and unregisters cleanly;
- no real probe starts because `allow_hw_probe=0` and no verified OV5647 DT node is active.
