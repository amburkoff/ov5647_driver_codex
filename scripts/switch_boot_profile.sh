#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=./lib.sh
source "${SCRIPT_DIR}/lib.sh"

usage() {
    cat <<'EOF'
Usage:
  ./scripts/switch_boot_profile.sh [--default safe|dev] [--dev-overlay /boot/<name>.dtbo] [--render-only]
  sudo ./scripts/switch_boot_profile.sh --apply [--default safe|dev] [--dev-overlay /boot/<name>.dtbo]

By default the script renders a candidate extlinux.conf under artifacts/boot/
without modifying the live boot configuration.
EOF
}

APPLY=0
DEFAULT_PROFILE="safe"
EXTLINUX=/boot/extlinux/extlinux.conf
DEV_OVERLAY=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --apply)
            APPLY=1
            shift
            ;;
        --render-only)
            APPLY=0
            shift
            ;;
        --default)
            DEFAULT_PROFILE=${2:?missing profile name}
            shift 2
            ;;
        --dev-overlay)
            DEV_OVERLAY=${2:?missing overlay path}
            shift 2
            ;;
        --help|-h)
            usage
            exit 0
            ;;
        *)
            printf "unknown argument: %s\n" "$1" >&2
            usage >&2
            exit 1
            ;;
    esac
done

if [[ "${DEFAULT_PROFILE}" != "safe" && "${DEFAULT_PROFILE}" != "dev" ]]; then
    printf "default profile must be 'safe' or 'dev'\n" >&2
    exit 1
fi

if [[ -n "${DEV_OVERLAY}" && "${DEV_OVERLAY}" != /boot/* ]]; then
    printf "dev overlay path must be under /boot/: %s\n" "${DEV_OVERLAY}" >&2
    exit 1
fi

STAMP=$(timestamp_utc)
LOGFILE="${LOG_DIR}/${STAMP}-switch_boot_profile.log"
BOOT_DIR="${ARTIFACT_DIR}/boot/${STAMP}"
TMP_STANZA=$(mktemp)
trap 'rm -f "${TMP_STANZA}"' EXIT

mkdir -p "${BOOT_DIR}"
copy_if_readable "${EXTLINUX}" "${BOOT_DIR}/extlinux.conf.current"

CURRENT_DEFAULT=$(awk '$1 == "DEFAULT" { print $2; exit }' "${EXTLINUX}")
CURRENT_LABEL=${CURRENT_DEFAULT:-$(awk '$1 == "LABEL" { print $2; exit }' "${EXTLINUX}")}
TIMEOUT_VALUE=$(awk '$1 == "TIMEOUT" { print $2; exit }' "${EXTLINUX}")

awk -v target="${CURRENT_LABEL}" '
    $1 == "LABEL" {
        if (in_target) {
            exit
        }
        in_target = ($2 == target)
    }
    in_target {
        print
    }
' "${EXTLINUX}" >"${TMP_STANZA}"

MENU_LABEL=$(awk '/^[[:space:]]*MENU LABEL / { sub(/^[[:space:]]*MENU LABEL[[:space:]]+/, ""); print; exit }' "${TMP_STANZA}")
LINUX_LINE=$(awk '/^[[:space:]]*LINUX / { sub(/^[[:space:]]*LINUX[[:space:]]+/, ""); print; exit }' "${TMP_STANZA}")
INITRD_LINE=$(awk '/^[[:space:]]*INITRD / { sub(/^[[:space:]]*INITRD[[:space:]]+/, ""); print; exit }' "${TMP_STANZA}")
APPEND_LINE=$(awk '/^[[:space:]]*APPEND / { sub(/^[[:space:]]*APPEND[[:space:]]+/, ""); print; exit }' "${TMP_STANZA}")
FDT_LINE=$(awk '/^[[:space:]]*FDT / { sub(/^[[:space:]]*FDT[[:space:]]+/, ""); print; exit }' "${TMP_STANZA}")
FDTOVERLAYS_LINE=$(awk '/^[[:space:]]*FDTOVERLAYS / { sub(/^[[:space:]]*FDTOVERLAYS[[:space:]]+/, ""); print; exit }' "${TMP_STANZA}")

if [[ -z "${LINUX_LINE}" || -z "${APPEND_LINE}" ]]; then
    printf "failed to extract a boot stanza from %s\n" "${EXTLINUX}" >&2
    exit 1
fi

if [[ -z "${INITRD_LINE}" ]]; then
    INITRD_LINE="/boot/initrd"
fi

APPEND_LINE=$(printf "%s\n" "${APPEND_LINE}" | sed -E 's/(^|[[:space:]])boot_profile=[^[:space:]]+//g; s/[[:space:]]+/ /g; s/^ //; s/ $//')

if [[ -z "${TIMEOUT_VALUE}" ]]; then
    TIMEOUT_VALUE="30"
fi

GENERATED="${BOOT_DIR}/extlinux.conf.generated"
DEFAULT_LABEL="ov5647-safe"
if [[ "${DEFAULT_PROFILE}" == "dev" ]]; then
    DEFAULT_LABEL="ov5647-dev"
fi

{
    printf "TIMEOUT %s\n" "${TIMEOUT_VALUE}"
    printf "DEFAULT %s\n\n" "${DEFAULT_LABEL}"
    printf "MENU TITLE L4T boot options\n\n"

    printf "LABEL ov5647-safe\n"
    printf "      MENU LABEL Jetson SAFE (no OV5647 auto-load)\n"
    printf "      LINUX %s\n" "${LINUX_LINE}"
    printf "      INITRD %s\n" "${INITRD_LINE}"
    if [[ -n "${FDT_LINE}" ]]; then
        printf "      FDT %s\n" "${FDT_LINE}"
    fi
    if [[ -n "${FDTOVERLAYS_LINE}" ]]; then
        printf "      FDTOVERLAYS %s\n" "${FDTOVERLAYS_LINE}"
    fi
    printf "      APPEND %s boot_profile=ov5647-safe\n\n" "${APPEND_LINE}"

    printf "LABEL ov5647-dev\n"
    printf "      MENU LABEL Jetson DEV OV5647 auto-load\n"
    printf "      LINUX %s\n" "${LINUX_LINE}"
    printf "      INITRD %s\n" "${INITRD_LINE}"
    if [[ -n "${FDT_LINE}" ]]; then
        printf "      FDT %s\n" "${FDT_LINE}"
    fi
    if [[ -n "${DEV_OVERLAY}" ]]; then
        printf "      FDTOVERLAYS %s" "${DEV_OVERLAY}"
        if [[ -n "${FDTOVERLAYS_LINE}" ]]; then
            printf " %s" "${FDTOVERLAYS_LINE}"
        fi
        printf "\n"
    elif [[ -n "${FDTOVERLAYS_LINE}" ]]; then
        printf "      FDTOVERLAYS %s\n" "${FDTOVERLAYS_LINE}"
    fi
    printf "      APPEND %s boot_profile=ov5647-dev\n" "${APPEND_LINE}"
} >"${GENERATED}"

{
    note "Rendered candidate boot profile config"
    note "Source label: ${CURRENT_LABEL}"
    note "Source menu label: ${MENU_LABEL:-unknown}"
    note "Requested default profile: ${DEFAULT_PROFILE}"
    note "Requested dev overlay: ${DEV_OVERLAY:-unset}"
    note "Generated config: ${GENERATED}"
} | tee "${LOGFILE}"

if [[ "${APPLY}" -eq 1 ]]; then
    require_root
    cp -- "${EXTLINUX}" "${EXTLINUX}.${STAMP}.bak"
    cp -- "${GENERATED}" "${EXTLINUX}"
    sync
    note "Applied generated extlinux.conf and backed up the previous file to ${EXTLINUX}.${STAMP}.bak" | tee -a "${LOGFILE}"
else
    note "Render-only mode; live extlinux.conf was not modified" | tee -a "${LOGFILE}"
fi
