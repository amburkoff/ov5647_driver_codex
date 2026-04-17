#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=./lib.sh
source "${SCRIPT_DIR}/lib.sh"

STAMP=$(timestamp_utc)
LOGFILE="${LOG_DIR}/${STAMP}-collect_env.log"
DT_DIR="${ARTIFACT_DIR}/device-tree/${STAMP}"
BOOT_DIR="${ARTIFACT_DIR}/boot/${STAMP}"
REF_DIR="${ARTIFACT_DIR}/reference-overlays/${STAMP}"

mkdir -p "${DT_DIR}" "${BOOT_DIR}" "${REF_DIR}"

{
    note "Starting environment collection"
    note "Repository root: ${REPO_ROOT}"
    note "Boot profile token: $(boot_profile_from_cmdline)"
} | tee "${LOGFILE}"

save_cmd_output "${LOG_DIR}/${STAMP}-uname.log" uname -a
save_cmd_output "${LOG_DIR}/${STAMP}-date.log" date -Is
save_cmd_output "${LOG_DIR}/${STAMP}-uptime-s.log" uptime -s
save_cmd_output "${LOG_DIR}/${STAMP}-nv_tegra_release.log" cat /etc/nv_tegra_release
save_cmd_output "${LOG_DIR}/${STAMP}-cmdline.log" cat /proc/cmdline
save_cmd_output "${LOG_DIR}/${STAMP}-git-status.log" git -C "${REPO_ROOT}" status --short --branch
save_cmd_output "${LOG_DIR}/${STAMP}-git-remote.log" git -C "${REPO_ROOT}" remote -v
save_cmd_output "${LOG_DIR}/${STAMP}-lsmod.log" lsmod
save_cmd_output "${LOG_DIR}/${STAMP}-dpkg-l4t.log" dpkg-query -W -f='${Package} ${Version}\n' nvidia-l4t-camera nvidia-l4t-core nvidia-l4t-kernel
save_cmd_output "${LOG_DIR}/${STAMP}-apt-policy-jetpack.log" bash -lc "apt-cache policy nvidia-jetpack nvidia-l4t-core nvidia-l4t-kernel"
save_cmd_output "${LOG_DIR}/${STAMP}-journalctl-list-boots.log" bash -lc "journalctl --list-boots 2>&1 || true"
save_cmd_output "${LOG_DIR}/${STAMP}-i2cdetect-list.log" i2cdetect -l
save_cmd_output "${LOG_DIR}/${STAMP}-which-tools.log" bash -lc "which dtc i2cdetect modinfo journalctl v4l2-ctl media-ctl v4l2-compliance || true"
save_cmd_output "${LOG_DIR}/${STAMP}-video-nodes.log" bash -lc "ls -l /dev/media* /dev/video* 2>&1 || true"

copy_if_readable /boot/extlinux/extlinux.conf "${BOOT_DIR}/extlinux.conf"
copy_if_readable /boot/extlinux/extlinux.conf.nv-update-extlinux-backup "${BOOT_DIR}/extlinux.conf.nv-update-extlinux-backup"

tr -d '\000' </proc/device-tree/model >"${DT_DIR}/model.txt"
printf "\n" >>"${DT_DIR}/model.txt"
tr -d '\000' </proc/device-tree/compatible >"${DT_DIR}/compatible.txt"
printf "\n" >>"${DT_DIR}/compatible.txt"
tr -d '\000' </proc/device-tree/chosen/ids >"${DT_DIR}/chosen-ids.txt"
printf "\n" >>"${DT_DIR}/chosen-ids.txt"
tr -d '\000' </proc/device-tree/chosen/nvidia,sku >"${DT_DIR}/chosen-nvidia-sku.txt"
printf "\n" >>"${DT_DIR}/chosen-nvidia-sku.txt"
dtc -I fs -O dts /proc/device-tree >"${DT_DIR}/live-device-tree.dts" 2>"${DT_DIR}/dtc.stderr.log" || true

dtc -I dtb -O dts /boot/tegra234-p3767-camera-p3768-imx219-A.dtbo >"${REF_DIR}/tegra234-p3767-camera-p3768-imx219-A.dts" 2>"${REF_DIR}/imx219-A.stderr.log" || true
dtc -I dtb -O dts /boot/tegra234-p3767-camera-p3768-imx219-C.dtbo >"${REF_DIR}/tegra234-p3767-camera-p3768-imx219-C.dts" 2>"${REF_DIR}/imx219-C.stderr.log" || true

{
    note "Environment collection finished"
    note "Saved logs under ${LOG_DIR}"
    note "Saved DT artifacts under ${DT_DIR}"
    note "Saved boot snapshots under ${BOOT_DIR}"
    note "Saved reference overlays under ${REF_DIR}"
} | tee -a "${LOGFILE}"
