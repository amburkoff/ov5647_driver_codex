# 2026-04-20 Fourth Reboot RMMOD Hang

## What Happened

- the user manually ran:
  - `sudo /home/cam/ov5647_driver_codex/scripts/run_manual_rmmod_trace.sh`
- the helper printed:
  - `[20260420T104858Z] starting live dmesg capture`
  - `[20260420T104858Z] running: rmmod nv_ov5647`
- the Jetson hung during unload;
- the user then manually rebooted the board.

## Collected Artifacts

- pre-unload trace files survived:
  - `logs/20260420T104858Z-rmmod-trace.log`
  - `logs/20260420T104858Z-rmmod-live-dmesg.log`
  - `logs/20260420T104858Z-rmmod-pre-dmesg-tail.log`
- post-reboot collection saved:
  - `artifacts/post-reboot/20260420T105141Z/`
  - `logs/20260420T105141Z-collect_post_reboot.log`

## What Is Confirmed

- `/proc/cmdline` after reboot still reports:
  - `boot_profile=ov5647-dev`
- `pstore` remained empty on this reboot:
  - `artifacts/post-reboot/20260420T105141Z/pstore-ls.log`
  - `artifacts/post-reboot/20260420T105141Z/pstore-find.log`
- the preserved pre-unload dmesg tail ends at successful probe:
  - `ov5647_probe: exit success`
  - `nv_ov5647: i2c driver registered`
- no `ov5647_remove` markers appeared in the preserved live-dmesg trace.

## Interpretation

- the hang boundary is earlier than the currently instrumented remove body, or hard enough that printk output is not flushed once unload starts;
- one plausible boundary is `module_exit -> i2c_del_driver()` before `ov5647_remove()` emits any visible marker;
- this hang is independent from the earlier NULL-dereference crash fixed in `ov5647_power_off()`.

## Corrective Action Applied

- added explicit module-exit markers around:
  - `before i2c_del_driver`
  - `after i2c_del_driver`
- expanded the manual unload helper to save a larger pre-rmmod kernel tail and record the loaded-module state before issuing `sudo rmmod`.

## Next Smallest Step

1. Rebuild the module with the new exit-path markers.
2. Ask the user to manually run one `insmod`.
3. Ask the user to manually run one unload helper invocation.
4. After reboot or return, compare whether the last visible marker is:
   - before `i2c_del_driver`
   - inside `ov5647_remove`
   - after `tegracam_v4l2subdev_unregister`
   - after `tegracam_device_unregister`

## Reboot Needed

- No reboot is needed before the next manual unload test.

## Default Boot Profile On Disk

- `ov5647-dev`
