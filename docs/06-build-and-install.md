# Build And Install

## External Module Build

Build the current skeleton module:

```bash
./scripts/build_module.sh
```

What it does:

- builds `src/nv_ov5647/nv_ov5647.c` as an external kernel module against `/lib/modules/$(uname -r)/build`;
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

- no device-tree match table yet;
- no I2C probe yet;
- no sensor power sequencing yet;
- no boot-time auto-load path.

This is deliberate. The first objective is to validate a clean LKM build and lifecycle loop before touching hardware.

