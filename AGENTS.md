# AGENTS.md

## Mission

This repository exists to develop, validate, document, and maintain a **working OV5647 MIPI CSI-2 camera driver for Jetson Orin NX on L4T R36.5 / JetPack 6.2.2**, with a strict focus on:

- minimal reboot count during development;
- zero tolerance for boot hangs and module-load hangs;
- persistent logs on disk;
- reproducible tests;
- small safe steps;
- regular git commits and pushes;
- complete Markdown documentation.

The final outcome is not just code. It is a reproducible engineering result:
- working driver,
- working DT/overlay,
- safe and dev boot profiles,
- recovery path,
- test suite,
- reports,
- logs,
- image shown from the camera.

---

## Target hardware profile

Primary target hardware for this repository:
- **Jetson Orin NX on CLB Developer Kit carrier**
- **L4T R36.5 / JetPack 6.2.2**
- **OV5647 over MIPI CSI-2**

Carrier-specific rule:
Treat the **CLB Developer Kit as a carrier-specific bring-up target**, not as a generic Jetson board.
Do not assume GPIO, regulator, I2C, CSI-port, or connector details until verified from:
- the live system DT / procfs / sysfs state;
- the active boot configuration;
- carrier board schematics or vendor docs if available;
- physical connector/cable/adaptor inspection.

Known practical bias for Orin NX developer-carrier style bring-up:
- prefer **2-lane CSI operation** first for OV5647;
- prefer a **single-port, single-sensor** initial target;
- prefer **manual module load** before any boot-time auto-load;
- if the carrier exposes Raspberry Pi style camera connectivity through 22-pin Jetson CSI connectors, verify the exact cable/adaptor orientation before power and stream tests.

Mandatory early deliverable:
Create `docs/01a-clb-carrier-mapping.md` with the verified mapping for:
- carrier board identity and revision;
- CSI connector name actually used;
- sensor-side connector/cable/adaptor path;
- I2C controller and sensor address;
- reset/pwdn GPIOs;
- mclk source;
- regulators/supplies;
- DT nodes and overlay fragments touched by the project.

---

## Ground truth and references

### Source priority
Use sources in this order:

1. **Official NVIDIA Jetson Linux r36.5 documentation**
2. **Official NVIDIA JetPack 6.2.2 / Jetson Linux 36.5 release documentation**
3. **Official NVIDIA BSP / kernel sources for r36.5**
4. **Official Linux media / V4L2 documentation**
5. **Upstream Linux `drivers/media/i2c/ov5647.c`**
6. NVIDIA forums / community examples / GitHub references

If a community example conflicts with official NVIDIA documentation for r36.5, follow the official NVIDIA documentation.

### Architecture bias
Prefer the **current Jetson V4L2 camera framework** and current r36.x sample driver style.
Do not blindly transplant code from JetPack 5.x or earlier.

---

## Development principles

### 1. Safety first
Never prioritize speed over recoverability.

Before enabling any boot-time auto-load path, prove that:
- manual load works;
- manual unload works;
- probe succeeds consistently;
- error unwind is safe;
- no kernel warnings/oops/panic/hang are introduced.

### 2. LKM-first
Use a loadable kernel module as the default development loop whenever possible:
- edit
- rebuild
- `rmmod`
- `insmod`
- retest

Avoid reboot unless truly required by:
- device tree / overlay changes
- boot profile changes
- non-runtime-applied configuration changes

### 3. Small steps only
Move from simple to complex:

1. platform inventory
2. repository scaffolding
3. logging and reporting infrastructure
4. skeleton driver
5. module build
6. safe manual load/unload
7. I2C and chip ID
8. DT/overlay
9. `/dev/videoX`
10. V4L2 validation
11. raw capture
12. preview
13. stress
14. boot-time auto-load validation
15. stabilization and documentation

Do not skip stages.

### 4. One variable at a time
When debugging:
- change one hypothesis at a time;
- log before/after;
- save artifacts;
- write down the current explanation of failure.

Do not mix unrelated changes into the same experiment.

---

## Hard requirements

### No hang policy
The driver must **not** cause:
- boot hang;
- hang on probe;
- hang on `insmod`;
- hang on `rmmod`;
- hang on stream-on/off;
- repeated reboot instability.

If a change introduces instability, back it out or isolate it behind a non-default path.

### Logging policy
Every meaningful action must leave logs on disk.

Required saved artifacts include at minimum:
- `uname -a`
- `/etc/nv_tegra_release`
- `/proc/cmdline`
- `dmesg`
- `journalctl -k`
- `lsmod`
- `modinfo`
- `v4l2-ctl --list-devices`
- `v4l2-ctl --all`
- `v4l2-ctl --list-formats-ext`
- `v4l2-compliance`
- media topology output
- DT / overlay dumps
- extlinux configuration snapshots
- pstore / ramoops logs after abnormal reboot

### Documentation policy
Document continuously, not at the end.

Keep `docs/`, `reports/`, and `README.md` current while developing.

Every nontrivial change should update at least one of:
- design docs
- test plan
- status/results
- known issues
- report file

### Git policy
Commit and push frequently.

Commit after each green checkpoint, with small meaningful messages.
Push after significant commits.

If push fails:
- save the error to logs;
- report it;
- fix it before continuing too far.

---

## Repository structure expectations

Expected structure:

- `README.md`
- `AGENTS.md`
- `docs/`
- `reports/`
- `logs/`
- `artifacts/`
- `scripts/`
- `patches/`
- driver source tree / module files

Recommended docs:
- `docs/00-project-scope.md`
- `docs/01-platform-inventory.md`
- `docs/02-hardware-assumptions.md`
- `docs/03-sources-and-references.md`
- `docs/04-driver-architecture.md`
- `docs/05-dt-overlay-design.md`
- `docs/06-build-and-install.md`
- `docs/07-test-plan.md`
- `docs/08-debug-playbook.md`
- `docs/09-boot-profiles-and-recovery.md`
- `docs/10-results-and-status.md`
- `docs/11-known-issues.md`

Recommended scripts:
- `scripts/collect_env.sh`
- `scripts/capture_kernel_logs.sh`
- `scripts/build_module.sh`
- `scripts/install_module.sh`
- `scripts/unload_module.sh`
- `scripts/switch_boot_profile.sh`
- `scripts/run_smoke_tests.sh`
- `scripts/run_v4l2_tests.sh`
- `scripts/run_stream_stress.sh`
- `scripts/run_argus_tests.sh`
- `scripts/collect_post_reboot.sh`
- `scripts/recover_safe_boot.sh`

---

## Boot profile policy

Maintain **two boot entries** at all times:

### Safe profile
A profile with no experimental OV5647 boot-time auto-load.
Readable label example:
- `Jetson SAFE (no OV5647 auto-load)`

### Dev profile
A profile intended for OV5647 auto-load and overlay validation.
Readable label example:
- `Jetson DEV OV5647 auto-load`

### Default selection policy
When a reboot is required to test the development path:
- set the intended profile as `DEFAULT`;
- keep the safe profile available in the boot menu.

### Boot identity policy
Each boot entry must carry a unique kernel cmdline token:
- `boot_profile=ov5647-safe`
- `boot_profile=ov5647-dev`

After every reboot, confirm the active profile with:
- `cat /proc/cmdline`

Record the detected profile in the next report.

### Recovery policy
Never remove the safe profile.
Never leave the system in a state where only the experimental profile exists.

---

## Reboot policy

The agent must minimize reboots.

If a reboot is necessary:
1. explain why;
2. state which boot profile was set as default;
3. ask the user to run exactly:
   - `sudo reboot`

Do not rely on the user to manually remember the desired boot profile if the default can be preconfigured safely.

After reconnect / return from reboot, immediately:
1. read `/proc/cmdline`;
2. determine active boot profile;
3. collect post-boot logs;
4. collect pstore/ramoops if present;
5. create a post-reboot report.

---

## Hardware discovery policy

Do not silently assume hardware facts.
For the **CLB Developer Kit** specifically, the first hardware-discovery pass must explicitly determine whether the camera path is wired like the NVIDIA Orin Nx developer carrier or requires carrier-specific DT/overlay routing. Do not assume CAM0/CAM1 mapping until verified.


You must determine and document:
- module / carrier board combination;
- active DTB;
- CSI port / interface used;
- lane count;
- lane polarity;
- I2C bus and address;
- reset/pwdn GPIOs;
- clock source and frequency;
- regulators and supply names;
- connector / adapter board details;
- EEPROM presence or absence.

Use:
- live system inspection
- device tree
- official board docs
- camera overlay examples
- vendor docs
- reliable internet sources

Any unresolved fact must be documented as an assumption with risk.

---

## Driver implementation policy

### Preferred strategy
Use NVIDIA sample camera drivers as structural templates and upstream OV5647 as the sensor-specific reference.

Use community Jetson OV5647 code only as a cross-check.

### Initial scope
For the first milestone on the CLB Developer Kit, scope the target to **one OV5647 sensor on one verified CSI connector** only.

Start with the minimal useful implementation:
- safe probe
- safe remove
- chip ID read
- one known-good mode
- one working raw capture path
- one working preview path

Do not start by implementing every mode and every control.

### Error handling
Every critical function must:
- log entry/exit or enough context;
- log failures with explicit error codes;
- unwind resources safely.

Critical paths include:
- parse DT
- power on/off
- regulator handling
- GPIO handling
- clock handling
- probe/remove
- control setup
- mode write
- stream on/off

### Mode table policy
Start with the smallest stable mode set.
Add more modes only after one mode is proven stable end to end.

Mode definitions must stay aligned with DT mode entries.

---

## Testing policy

Testing is mandatory at each stage.

### Required test categories

#### A. Static / source checks
- code sanity
- error path review
- logging coverage review
- resource lifetime review

#### B. Build tests
- clean build
- rebuild
- module artifact verification
- `modinfo`

#### C. Inventory tests
- platform versions
- board identity
- current boot config
- DT inspection
- I2C bus visibility
- GPIO/regulator/clock inspection

#### D. Module lifecycle tests
- `insmod`
- `rmmod`
- repeated load/unload cycles
- no warning / no hang policy

#### E. Probe tests
- with sensor present
- with sensor absent if feasible
- wrong chip-id / failure-path behavior
- safe unwind after failure

#### F. DT / overlay tests
- overlay compile
- overlay apply
- safe boot entry
- dev boot entry
- live DT verification
- mode-node verification
- lane / endpoint correctness

#### G. V4L2 / media tests
- `/dev/videoX`
- `v4l2-ctl --list-devices`
- `v4l2-ctl --all`
- `v4l2-ctl --list-formats-ext`
- `v4l2-compliance`
- `media-ctl -p`
- controls
- stream start/stop

#### H. Raw capture tests
- single frame
- multi-frame
- file-size sanity
- image-not-empty sanity
- Bayer/raw plausibility checks

#### I. Preview tests
At least one stable path to visible image is required:
- preferred: V4L2 raw + userspace demosaic / preview
- optional/additional: GStreamer path
- Argus only after basic V4L2 success, not before

#### J. Stress tests
- repeated stream on/off
- repeated capture
- repeated module load/unload
- long preview
- repeated reboot smoke tests

#### K. Reboot resilience tests
- safe profile reboot
- dev profile reboot
- profile detection
- pstore/ramoops inspection
- post-reboot log collection

#### L. Final acceptance tests
Success requires:
- stable boot
- stable module lifecycle
- stable raw capture
- visible image
- docs and logs
- recovery path

---

## Reporting policy

After each meaningful step, update a markdown report with:
- what changed
- files changed
- commands run
- logs saved
- tests passed
- tests failed
- current root-cause hypotheses
- next smallest step
- whether reboot is needed
- which boot profile is default

Keep reports factual and terse.

---

## What not to do

- Do not blindly port an old r35 or r32 driver.
- Do not enable risky auto-load too early.
- Do not remove the safe boot entry.
- Do not batch many unrelated changes before testing.
- Do not claim success without a visible image.
- Do not hide failures in Argus / ISP / V4L2.
- Do not leave experiments undocumented.
- Do not continue after a suspicious kernel warning without recording it.

---

## First actions for any agent entering this repo

1. Read:
   - `README.md`
   - `AGENTS.md`
   - latest files in `docs/`
   - latest files in `reports/`
2. Confirm the active platform and current boot profile.
3. Snapshot current environment into logs.
4. Inspect current branch / git status / remote sync state.
5. Continue from the smallest safe next step, not from assumptions.

---

## Definition of done

Done means all of the following are true:

- the Jetson boots reliably;
- safe boot profile exists and works;
- dev boot profile exists and works;
- OV5647 driver is implemented for r36.5;
- probe/remove are stable;
- no hangs on module operations;
- raw capture works;
- live image is shown from the camera;
- repo contains full source, scripts, logs, reports, and docs;
- recovery procedure is documented and tested;
- work is committed and pushed to GitHub.
