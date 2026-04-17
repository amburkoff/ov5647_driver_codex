#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=./lib.sh
source "${SCRIPT_DIR}/lib.sh"

require_cmd make

STAMP=$(timestamp_utc)
KDIR=${KDIR:-/lib/modules/$(uname -r)/build}
SRC_DIR="${REPO_ROOT}/src/nv_ov5647"
OUT_DIR="${ARTIFACT_DIR}/build/${STAMP}"
LOGFILE="${LOG_DIR}/${STAMP}-build_module.log"

mkdir -p "${OUT_DIR}"

{
    note "Building nv_ov5647 external module"
    note "Kernel headers: ${KDIR}"
    note "Source dir: ${SRC_DIR}"
} | tee "${LOGFILE}"

make -C "${KDIR}" M="${SRC_DIR}" modules 2>&1 | tee -a "${LOGFILE}"

cp -- "${SRC_DIR}/nv_ov5647.ko" "${OUT_DIR}/"
cp -- "${SRC_DIR}/Module.symvers" "${OUT_DIR}/"
cp -- "${SRC_DIR}/modules.order" "${OUT_DIR}/"

modinfo "${SRC_DIR}/nv_ov5647.ko" >"${OUT_DIR}/nv_ov5647.modinfo.txt"

{
    note "Build finished"
    note "Artifacts saved under ${OUT_DIR}"
} | tee -a "${LOGFILE}"

