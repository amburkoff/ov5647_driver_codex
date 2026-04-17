#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=./lib.sh
source "${SCRIPT_DIR}/lib.sh"

require_root

EXTLINUX=/boot/extlinux/extlinux.conf
STAMP=$(timestamp_utc)
LOGFILE="${LOG_DIR}/${STAMP}-recover_safe_boot.log"
TMP_FILE=$(mktemp)
trap 'rm -f "${TMP_FILE}"' EXIT

{
    note "Recovering safe boot profile"
} | tee "${LOGFILE}"

if ! grep -q '^LABEL ov5647-safe$' "${EXTLINUX}"; then
    note "Safe label missing; generating and applying fresh safe/dev entries first" | tee -a "${LOGFILE}"
    "${SCRIPT_DIR}/switch_boot_profile.sh" --apply --default safe | tee -a "${LOGFILE}"
    exit 0
fi

cp -- "${EXTLINUX}" "${EXTLINUX}.${STAMP}.bak"
awk '
    BEGIN { replaced = 0 }
    $1 == "DEFAULT" && !replaced {
        print "DEFAULT ov5647-safe"
        replaced = 1
        next
    }
    { print }
    END {
        if (!replaced) {
            print "DEFAULT ov5647-safe"
        }
    }
' "${EXTLINUX}" >"${TMP_FILE}"

cp -- "${TMP_FILE}" "${EXTLINUX}"
sync

note "Set DEFAULT ov5647-safe and backed up previous extlinux.conf" | tee -a "${LOGFILE}"

