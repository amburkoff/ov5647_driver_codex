#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=./lib.sh
source "${SCRIPT_DIR}/lib.sh"

usage() {
    cat <<'EOF'
Usage:
  ./scripts/build_overlay.sh <path-to-overlay.dts>

Builds a DT overlay into artifacts/dtbo/<timestamp>-<name>.dtbo and writes a
timestamped build log under logs/.
EOF
}

if [[ $# -ne 1 ]]; then
    usage >&2
    exit 1
fi

require_cmd dtc

SRC=${1:?overlay path is required}
if [[ ! -f "${SRC}" ]]; then
    printf "overlay source not found: %s\n" "${SRC}" >&2
    exit 1
fi

STAMP=$(timestamp_utc)
OUT_DIR="${ARTIFACT_DIR}/dtbo"
BASE=$(basename "${SRC}")
NAME=${BASE%.dts}
OUT_FILE="${OUT_DIR}/${STAMP}-${NAME}.dtbo"
LOGFILE="${LOG_DIR}/${STAMP}-build_overlay-${NAME}.log"

mkdir -p "${OUT_DIR}"

{
    note "Building overlay"
    note "Source: ${SRC}"
    note "Output: ${OUT_FILE}"
    printf "$ dtc -@ -I dts -O dtb -o %s %s\n" "${OUT_FILE}" "${SRC}"
} | tee "${LOGFILE}"

dtc -@ -I dts -O dtb -o "${OUT_FILE}" "${SRC}" 2>&1 | tee -a "${LOGFILE}"

{
    note "Overlay build finished"
    note "Artifacts saved under ${OUT_FILE}"
} | tee -a "${LOGFILE}"

