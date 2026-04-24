#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=./lib.sh
source "${SCRIPT_DIR}/lib.sh"

STAMP=$(timestamp_utc)
OUT_DIR="${ARTIFACT_DIR}/reference-baseline-state/${STAMP}"
LOGFILE="${LOG_DIR}/${STAMP}-collect_reference_baseline_state.log"

EXPECTED_PROFILE="ov5647-dev"
EXPECTED_OVERLAY="/boot/ov5647-p3768-port-c-reference.dtbo"
EXPECTED_NODE="/sys/firmware/devicetree/base/bus@0/cam_i2cmux/i2c@1/ov5647_c@36"
EXPECTED_BADGE="ov5647_reference_route_c"
EXPECTED_SYSFS_DEVICE_TREE="/sys/firmware/devicetree/base/bus@0/cam_i2cmux/i2c@1/ov5647_c@36"

mkdir -p "${OUT_DIR}"

dt_string() {
    local path=$1
    if [[ -r "${path}" ]]; then
        tr -d '\000' <"${path}"
    else
        printf "missing"
    fi
}

save_bool_check() {
    local file=$1
    local label=$2
    local actual=$3
    local expected=$4

    if [[ "${actual}" == "${expected}" ]]; then
        printf "PASS %s actual=%s expected=%s\n" "${label}" "${actual}" "${expected}" >>"${file}"
    else
        printf "FAIL %s actual=%s expected=%s\n" "${label}" "${actual}" "${expected}" >>"${file}"
    fi
}

{
    note "Collecting canonical route-C reference baseline state"
    note "Output directory: ${OUT_DIR}"
    note "Expected boot profile: ${EXPECTED_PROFILE}"
    note "Expected overlay: ${EXPECTED_OVERLAY}"
    note "Expected live node: ${EXPECTED_NODE}"
} | tee "${LOGFILE}"

save_cmd_output "${OUT_DIR}/cmdline.log" cat /proc/cmdline
save_cmd_output "${OUT_DIR}/uname.log" uname -a
save_cmd_output "${OUT_DIR}/nv_tegra_release.log" cat /etc/nv_tegra_release
save_cmd_output "${OUT_DIR}/lsmod-camera.log" bash -lc "lsmod | grep -E '^(nv_ov5647|nvhost_nvcsi|nvhost_vi5|tegra_camera|capture_ivc|tegra_camera_rtcpu)\\b|^Module' || true"
save_cmd_output "${OUT_DIR}/devnodes.log" bash -lc "ls -l /dev/media* /dev/video* /dev/v4l-subdev* 2>&1 || true"
save_cmd_output "${OUT_DIR}/v4l2-list-devices.log" bash -lc "v4l2-ctl --list-devices 2>&1 || true"
save_cmd_output "${OUT_DIR}/media-ctl.log" bash -lc "media-ctl -p 2>&1 || true"
save_cmd_output "${OUT_DIR}/journalctl-k-b.log" bash -lc "journalctl -k -b 2>&1 || true"
copy_if_readable /boot/extlinux/extlinux.conf "${OUT_DIR}/extlinux.conf"
save_cmd_output "${OUT_DIR}/pstore-find.log" bash -lc "find /sys/fs/pstore -maxdepth 1 -type f 2>&1 || true"
save_cmd_output "${OUT_DIR}/pstore-list.log" bash -lc "ls -la /sys/fs/pstore 2>&1 || true"

ASSERTIONS_FILE="${OUT_DIR}/assertions.log"

{
    echo "# Canonical Route-C Baseline Assertions"

    actual_profile=$(boot_profile_from_cmdline)
    save_bool_check "${ASSERTIONS_FILE}" "boot_profile" "${actual_profile}" "${EXPECTED_PROFILE}"

    if grep -Fq "OVERLAYS ${EXPECTED_OVERLAY}" /boot/extlinux/extlinux.conf; then
        echo "PASS extlinux_overlay actual=${EXPECTED_OVERLAY} expected=${EXPECTED_OVERLAY}" >>"${ASSERTIONS_FILE}"
    else
        echo "FAIL extlinux_overlay actual=missing expected=${EXPECTED_OVERLAY}" >>"${ASSERTIONS_FILE}"
    fi

    if [[ -d "${EXPECTED_NODE}" ]]; then
        echo "PASS live_node actual=present expected=present" >>"${ASSERTIONS_FILE}"
    else
        echo "FAIL live_node actual=missing expected=present" >>"${ASSERTIONS_FILE}"
    fi

    badge=$(dt_string /sys/firmware/devicetree/base/tegra-camera-platform/modules/module1/badge)
    save_bool_check "${ASSERTIONS_FILE}" "module1.badge" "${badge}" "${EXPECTED_BADGE}"

    sysfs_path=$(dt_string /sys/firmware/devicetree/base/tegra-camera-platform/modules/module1/drivernode0/sysfs-device-tree)
    save_bool_check "${ASSERTIONS_FILE}" "module1.sysfs-device-tree" "${sysfs_path}" "${EXPECTED_SYSFS_DEVICE_TREE}"

    if [[ -d "${EXPECTED_NODE}/mode0" ]]; then
        save_bool_check "${ASSERTIONS_FILE}" "mode0.tegra_sinterface" \
            "$(dt_string "${EXPECTED_NODE}/mode0/tegra_sinterface")" "serial_c"
        save_bool_check "${ASSERTIONS_FILE}" "mode0.lane_polarity" \
            "$(dt_string "${EXPECTED_NODE}/mode0/lane_polarity")" "0"
        save_bool_check "${ASSERTIONS_FILE}" "mode0.num_lanes" \
            "$(dt_string "${EXPECTED_NODE}/mode0/num_lanes")" "2"
        save_bool_check "${ASSERTIONS_FILE}" "mode0.discontinuous_clk" \
            "$(dt_string "${EXPECTED_NODE}/mode0/discontinuous_clk")" "yes"
        save_bool_check "${ASSERTIONS_FILE}" "mode0.cil_settletime" \
            "$(dt_string "${EXPECTED_NODE}/mode0/cil_settletime")" "0"
    else
        echo "FAIL mode0 actual=missing expected=present" >>"${ASSERTIONS_FILE}"
    fi
} >/dev/null

{
    echo "expected_node=${EXPECTED_NODE}"
    if [[ -d "${EXPECTED_NODE}" ]]; then
        echo "node=${EXPECTED_NODE}"
        for prop in compatible status reg devnode mclk sensor_model; do
            if [[ -r "${EXPECTED_NODE}/${prop}" ]]; then
                printf "%s=%s\n" "${prop}" "$(dt_string "${EXPECTED_NODE}/${prop}")"
            fi
        done
        if [[ -d "${EXPECTED_NODE}/mode0" ]]; then
            for prop in tegra_sinterface lane_polarity discontinuous_clk num_lanes cil_settletime pix_clk_hz line_length active_w active_h; do
                if [[ -r "${EXPECTED_NODE}/mode0/${prop}" ]]; then
                    printf "mode0.%s=%s\n" "${prop}" "$(dt_string "${EXPECTED_NODE}/mode0/${prop}")"
                fi
            done
        fi
    fi
} >"${OUT_DIR}/live-dt-reference-summary.log"

dtc -I fs -O dts /sys/firmware/devicetree/base >"${OUT_DIR}/live-device-tree.dts" 2>"${OUT_DIR}/dtc.stderr.log" || true

{
    note "Reference baseline collection finished"
    note "Saved state under ${OUT_DIR}"
    note "This helper is read-only; no module load, unload, stream, or reboot was performed"
} | tee -a "${LOGFILE}"
