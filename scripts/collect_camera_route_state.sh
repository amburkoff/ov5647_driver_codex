#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=./lib.sh
source "${SCRIPT_DIR}/lib.sh"

STAMP=$(timestamp_utc)
STATE_DIR="${ARTIFACT_DIR}/camera-route-state/${STAMP}"
LOGFILE="${LOG_DIR}/${STAMP}-collect_camera_route_state.log"

mkdir -p "${STATE_DIR}"

dt_string() {
    local path=$1

    if [[ -r "${path}" ]]; then
        tr -d '\000' <"${path}"
    else
        printf "missing"
    fi
}

dt_hex() {
    local path=$1

    if [[ -r "${path}" ]]; then
        od -An -tx1 -v "${path}" | tr -s ' ' | sed 's/^ //'
    else
        printf "missing"
    fi
}

copy_text_or_note() {
    local src=$1
    local dst=$2

    if [[ -r "${src}" ]]; then
        cp -- "${src}" "${dst}"
    else
        printf "unreadable or missing: %s\n" "${src}" >"${dst}"
    fi
}

{
    note "Starting read-only camera route state collection"
    note "Repository root: ${REPO_ROOT}"
    note "Boot profile token: $(boot_profile_from_cmdline)"
    note "State directory: ${STATE_DIR}"
} | tee "${LOGFILE}"

save_cmd_output "${STATE_DIR}/cmdline.log" cat /proc/cmdline
save_cmd_output "${STATE_DIR}/uname.log" uname -a
save_cmd_output "${STATE_DIR}/nv_tegra_release.log" cat /etc/nv_tegra_release
save_cmd_output "${STATE_DIR}/git-status.log" git -C "${REPO_ROOT}" status --short --branch --untracked-files=no
save_cmd_output "${STATE_DIR}/lsmod-nv-ov5647.log" bash -lc "lsmod | grep -E '^nv_ov5647|^Module' || true"
save_cmd_output "${STATE_DIR}/module-params.log" bash -lc 'if [ -d /sys/module/nv_ov5647/parameters ]; then for f in /sys/module/nv_ov5647/parameters/*; do printf "%s=" "$(basename "$f")"; cat "$f"; done; else echo "nv_ov5647 not loaded"; fi'
save_cmd_output "${STATE_DIR}/i2c-buses.log" i2cdetect -l
save_cmd_output "${STATE_DIR}/devnodes.log" bash -lc "ls -l /dev/media* /dev/video* /dev/v4l-subdev* 2>&1 || true"
save_cmd_output "${STATE_DIR}/v4l2-list-devices.log" bash -lc "v4l2-ctl --list-devices 2>&1 || true"
save_cmd_output "${STATE_DIR}/media-ctl.log" bash -lc "media-ctl -p 2>&1 || true"

copy_text_or_note /boot/extlinux/extlinux.conf "${STATE_DIR}/extlinux.conf"

{
    echo "# OV5647 live DT nodes"
    find /sys/firmware/devicetree/base -path '*ov5647*' -print 2>/dev/null | sort || true
    echo
    echo "# Selected OV5647 properties"
    mapfile -t ov5647_nodes < <(find /sys/firmware/devicetree/base -type d -name 'ov5647*' -print 2>/dev/null | sort || true)
    for node in "${ov5647_nodes[@]}"; do
        [[ -d "${node}" ]] || continue
        echo
        echo "node=${node}"
        for prop in compatible status reg devnode mclk tegra_sinterface num_lanes lane_polarity discontinuous_clk pix_clk_hz line_length active_w active_h mode_type pixel_phase csi_pixel_bit_depth; do
            if [[ -r "${node}/${prop}" ]]; then
                printf "%s=" "${prop}"
                dt_string "${node}/${prop}"
                printf "\n"
            fi
        done
        for prop in clocks pwdn-gpios reset-gpios port-index bus-width remote-endpoint; do
            if [[ -r "${node}/${prop}" ]]; then
                printf "%s_hex=" "${prop}"
                dt_hex "${node}/${prop}"
                printf "\n"
            fi
        done
        if [[ -d "${node}/mode0" ]]; then
            echo "mode0=${node}/mode0"
            for prop in num_lanes tegra_sinterface lane_polarity discontinuous_clk pix_clk_hz line_length active_w active_h mode_type pixel_phase csi_pixel_bit_depth; do
                if [[ -r "${node}/mode0/${prop}" ]]; then
                    printf "mode0.%s=" "${prop}"
                    dt_string "${node}/mode0/${prop}"
                    printf "\n"
                fi
            done
        fi
        if [[ -d "${node}/ports" ]]; then
            while IFS= read -r endpoint; do
                echo "endpoint=${endpoint}"
                for prop in port-index bus-width remote-endpoint; do
                    if [[ -r "${endpoint}/${prop}" ]]; then
                        printf "endpoint.%s_hex=" "${prop}"
                        dt_hex "${endpoint}/${prop}"
                        printf "\n"
                    fi
                done
            done < <(find "${node}/ports" -type d -name endpoint -print 2>/dev/null | sort || true)
        fi
    done
    echo
    echo "# Route-related endpoint symbols"
    if [[ -d /sys/firmware/devicetree/base/__symbols__ ]]; then
        mapfile -t ov5647_symbols < <(find /sys/firmware/devicetree/base/__symbols__ -type f -name '*ov5647*' -print 2>/dev/null | sort || true)
        for sym in "${ov5647_symbols[@]}"; do
            printf "%s=" "${sym#/sys/firmware/devicetree/base/__symbols__/}"
            dt_string "${sym}"
            printf "\n"
        done
    fi
} >"${STATE_DIR}/live-dt-ov5647-route-summary.log" 2>&1

dtc -I fs -O dts /sys/firmware/devicetree/base >"${STATE_DIR}/live-device-tree.dts" 2>"${STATE_DIR}/dtc.stderr.log" || true

{
    note "Camera route state collection finished"
    note "Saved state under ${STATE_DIR}"
    note "No module load, unload, streaming, or reboot was performed"
} | tee -a "${LOGFILE}"
