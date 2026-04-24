#!/usr/bin/env bash
set -euo pipefail

usage() {
	cat <<'EOF'
Usage:
  analyze_clk_pm_samples.sh <trace-dir>

Example:
  ./scripts/analyze_clk_pm_samples.sh artifacts/traces/20260424T101451Z
EOF
}

if [[ $# -ne 1 ]]; then
	usage >&2
	exit 1
fi

TRACE_DIR="$1"
SAMPLES_DIR="${TRACE_DIR}/clk-pm-samples"

if [[ ! -d "${SAMPLES_DIR}" ]]; then
	echo "clk-pm-samples directory not found under ${TRACE_DIR}" >&2
	exit 1
fi

python3 - "$SAMPLES_DIR" <<'PY'
from pathlib import Path
import sys

base = Path(sys.argv[1])
samples = sorted(p for p in base.iterdir() if p.is_dir())
if not samples:
    print("samples=0")
    sys.exit(0)

FIELDS = {
    "ext_en": "clk/extperiph1/clk_enable_count.log",
    "ext_prep": "clk/extperiph1/clk_prepare_count.log",
    "ext_rate": "clk/extperiph1/clk_rate.log",
    "nvcsi_en": "clk/nvcsi/clk_enable_count.log",
    "nvcsi_rate": "clk/nvcsi/clk_rate.log",
    "vi_en": "clk/vi/clk_enable_count.log",
    "vi_prep": "clk/vi/clk_prepare_count.log",
    "vi_rate": "clk/vi/clk_rate.log",
    "vi_state": "pm_genpd/vi/current_state.log",
    "vi_active": "pm_genpd/vi/active_time.log",
    "ispa_state": "pm_genpd/ispa/current_state.log",
}

def read_field(sample: Path, rel: str) -> str:
    p = sample / rel
    if not p.exists():
        return "MISSING"
    return p.read_text(errors="ignore").strip()

rows = []
for sample in samples:
    row = {"sample": sample.name}
    for key, rel in FIELDS.items():
        row[key] = read_field(sample, rel)
    rows.append(row)

def to_int(val: str):
    try:
        return int(val.replace(" ms", ""))
    except Exception:
        return None

def max_int(key: str):
    vals = [to_int(r[key]) for r in rows]
    vals = [v for v in vals if v is not None]
    return max(vals) if vals else None

print(f"samples={len(rows)}")
print(f"first_sample={rows[0]['sample']}")
print(f"last_sample={rows[-1]['sample']}")
print(f"max_ext_enable_count={max_int('ext_en')}")
print(f"max_ext_prepare_count={max_int('ext_prep')}")
print(f"max_nvcsi_enable_count={max_int('nvcsi_en')}")
print(f"max_vi_enable_count={max_int('vi_en')}")
print(f"max_vi_prepare_count={max_int('vi_prep')}")
print(f"max_vi_active_ms={max_int('vi_active')}")

transitions = []
prev = None
for r in rows:
    sig = (
        r["ext_en"], r["ext_prep"], r["nvcsi_en"], r["vi_en"],
        r["vi_prep"], r["vi_state"], r["ext_rate"], r["nvcsi_rate"], r["vi_rate"],
    )
    if sig != prev:
        transitions.append((r["sample"],) + sig)
        prev = sig

print("transitions=" + str(len(transitions)))
print("sample,ext_en,ext_prep,nvcsi_en,vi_en,vi_prep,vi_state,ext_rate,nvcsi_rate,vi_rate")
for t in transitions:
    print(",".join(t))

max_vi_en = max_int("vi_en")
max_nvcsi_en = max_int("nvcsi_en")
if (max_vi_en or 0) > 0 and (max_nvcsi_en or 0) > 0:
    print("clk_pm_signature=vi_and_nvcsi_clocks_observed_during_timeout")
elif (max_nvcsi_en or 0) > 0:
    print("clk_pm_signature=nvcsi_only_clock_activity_observed")
else:
    print("clk_pm_signature=no_receiver_clock_activity_observed")
PY
