#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat <<'EOF'
Usage: ./build.sh [--isa <isa>] [--cores N] [--out-dir DIR] [--coverage|--coverage-light|--no-coverage] [--clean] [--help] [-- extra_verilator_args...]

Build the Verilator CVA6 testharness binaries.

--isa can be specified multiple times. Defaults to building both rv64 and rv32.

Supported ISA values:
  rv32     (maps to cv32a6_imac_sv32)
  rv32f    (maps to cv32a6_full_sv32)
  rv64     (maps to cv64a6_full_sv39; includes F/D in this repo)
  rv64fd   (alias of rv64)

Unsupported in this repo:
  rv32fd   (rv32 full config has RVD=0)
  rv64f    (no rv64 config with RVD=0)

Notes:
  - This branch supports --cores 1 only. Use cx-2hart-build for multi-hart.
  - Use --out-dir (or env CX_OUT_DIR / OUT_DIR) to place final binaries in a
    shared artifacts folder. Intermediate Verilator work dirs stay under build_result/.

Extra arguments after "--" are forwarded to Verilator.
EOF
}

COVERAGE_MODE="${COVERAGE_MODE:-none}" # none|full|light
CLEAN=0
CORES="${CORES:-1}"
ISAS=()
OUT_DIR_OPT=""
EXTRA_VERILATOR_ARGS=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        --coverage|-c) COVERAGE_MODE="full" ;;
        --coverage-light) COVERAGE_MODE="light" ;;
        --no-coverage|-n) COVERAGE_MODE="none" ;;
        --clean) CLEAN=1 ;;
        --cores) CORES="$2"; shift ;;
        --isa) ISAS+=("$2"); shift ;;
        --out-dir)
            [[ $# -ge 2 ]] || { echo "ERROR: --out-dir requires a value" >&2; exit 2; }
            OUT_DIR_OPT="$2"; shift ;;
        --out-dir=*) OUT_DIR_OPT="${1#*=}" ;;
        --help|-h) usage; exit 0 ;;
        --) shift; EXTRA_VERILATOR_ARGS+=("$@"); break ;;
        *) EXTRA_VERILATOR_ARGS+=("$1") ;;
    esac
    shift || true
done

if [[ ${#ISAS[@]} -eq 0 ]]; then
    ISAS=("rv64" "rv32")
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

BUILD_ROOT="${BUILD_ROOT:-${ROOT_DIR}/build_result}"
VERILATOR_BIN="${VERILATOR:-verilator}"

OUT_DIR_DEFAULT="${ROOT_DIR}/build_result"
OUT_DIR="${OUT_DIR_OPT:-${CX_OUT_DIR:-${OUT_DIR:-${OUT_DIR_DEFAULT}}}}"

mkdir -p "$BUILD_ROOT" "$OUT_DIR"

if [[ ! "$CORES" =~ ^[0-9]+$ ]] || (( CORES < 1 )); then
    echo "Invalid --cores: $CORES" >&2
    exit 2
fi
if (( CORES != 1 )); then
    echo "This branch supports --cores 1 only (requested: $CORES)." >&2
    echo "Use cx-2hart-build for multi-hart builds." >&2
    exit 2
fi

build_target() {
    local isa="$1"
    local target=""
    local cov_suffix=""
    case "$COVERAGE_MODE" in
        full) cov_suffix="_cov" ;;
        light) cov_suffix="_cov_light" ;;
        none) cov_suffix="" ;;
    esac

    case "$isa" in
        rv32) target="cv32a6_imac_sv32" ;;
        rv32f) target="cv32a6_full_sv32" ;;
        rv64|rv64fd) isa="rv64"; target="cv64a6_full_sv39" ;;
        rv32fd) echo "Unsupported ISA: rv32fd"; exit 2 ;;
        rv64f) echo "Unsupported ISA: rv64f"; exit 2 ;;
        *) echo "Unknown ISA: ${isa}"; exit 2 ;;
    esac

    local ver_dir="${BUILD_ROOT}/work-ver-${isa}_${CORES}c${cov_suffix}"
    local out_bin="${OUT_DIR}/cva6_${isa}_${CORES}c${cov_suffix}"

    if (( CLEAN )); then
        rm -rf "${ver_dir}" "${out_bin}"
    fi

    # derive coverage flags per mode
    local cov_flag="0"
    local extra_args=("${EXTRA_VERILATOR_ARGS[@]}")
    case "$COVERAGE_MODE" in
        full)
            cov_flag="1"
            ;;
        light)
            cov_flag="0"
            extra_args+=(--coverage-line --coverage-user --coverage-max-width 0)
            ;;
        none)
            cov_flag="0"
            ;;
    esac

    echo "Building ${target}${cov_suffix} (verilator: ${VERILATOR_BIN})"
    make verilate \
        target="${target}" \
        ver-library="${ver_dir}" \
        COVERAGE="${cov_flag}" \
        EXTRA_VERILATOR_ARGS="${extra_args[*]} +define+CVA6_NUM_CORES=${CORES}" \
        verilator="${VERILATOR_BIN}"

    cp "${ver_dir}/Variane_testharness" "${out_bin}"
    chmod +x "${out_bin}"
    echo "  -> ${out_bin} (work dir: ${ver_dir})"
}

for isa in "${ISAS[@]}"; do
    build_target "$isa"
done

if [[ "$COVERAGE_MODE" == "full" || "$COVERAGE_MODE" == "light" ]]; then
    echo "Run the binary with +covfile=<path> to choose the coverage output .dat file (default: logs/coverage.dat)."
fi
