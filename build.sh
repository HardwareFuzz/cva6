#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat <<'EOF'
Usage: ./build.sh [--coverage|--coverage-light|--no-coverage] [--clean] [--rv64] [--rv32] [--help] [-- extra_verilator_args...]

Build the Verilator CVA6 testharness binaries. By default both RV64 (cv64a6_full_sv39)
and RV32 (cv32a6_full_sv32) variants are built. Pass --coverage to generate
coverage-instrumented binaries (_cov suffix), --coverage-light to generate
line/user-only coverage binaries (_cov_light suffix). Extra arguments after "--" are
forwarded to Verilator.
EOF
}

COVERAGE_MODE="${COVERAGE_MODE:-none}" # none|full|light
CLEAN=0
TARGETS=()
EXTRA_VERILATOR_ARGS=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        --coverage|-c) COVERAGE_MODE="full" ;;
        --coverage-light) COVERAGE_MODE="light" ;;
        --no-coverage|-n) COVERAGE_MODE="none" ;;
        --clean) CLEAN=1 ;;
        --rv64) TARGETS+=("cv64a6_full_sv39") ;;
        --rv32) TARGETS+=("cv32a6_full_sv32") ;;
        --help|-h) usage; exit 0 ;;
        --) shift; EXTRA_VERILATOR_ARGS+=("$@"); break ;;
        *) EXTRA_VERILATOR_ARGS+=("$1") ;;
    esac
    shift || true
done

if [[ ${#TARGETS[@]} -eq 0 ]]; then
    TARGETS=("cv64a6_full_sv39" "cv32a6_full_sv32")
fi

BUILD_ROOT="${BUILD_ROOT:-build_result}"
VERILATOR_BIN="${VERILATOR:-verilator}"

mkdir -p "$BUILD_ROOT"

build_target() {
    local target="$1"
    local arch_label="$2"
    local cov_suffix=""
    case "$COVERAGE_MODE" in
        full) cov_suffix="_cov" ;;
        light) cov_suffix="_cov_light" ;;
        none) cov_suffix="" ;;
    esac
    local ver_dir="${BUILD_ROOT}/work-ver-${arch_label}${cov_suffix}"
    local out_bin="${BUILD_ROOT}/cva6_${arch_label}${cov_suffix}"

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
        EXTRA_VERILATOR_ARGS="${extra_args[*]}" \
        verilator="${VERILATOR_BIN}"

    cp "${ver_dir}/Variane_testharness" "${out_bin}"
    echo "  -> ${out_bin} (work dir: ${ver_dir})"

    # copy to fuzz bin dir if exists
    local fuzz_dir="/home/canxin/Git/riscv_fuzz_test/riscv_impls_bins"
    if [[ -d "$fuzz_dir" ]]; then
        cp -f "${out_bin}" "${fuzz_dir}/$(basename "${out_bin}")"
        echo "  -> ${fuzz_dir}/$(basename "${out_bin}")"
    fi
}

for target in "${TARGETS[@]}"; do
    case "$target" in
        cv64*) build_target "$target" "rv64" ;;
        cv32*) build_target "$target" "rv32" ;;
        *) echo "Unknown target ${target}"; exit 1 ;;
    esac
done

if [[ "$COVERAGE_MODE" == "full" || "$COVERAGE_MODE" == "light" ]]; then
    echo "Run the binary with +covfile=<path> to choose the coverage output .dat file (default: logs/coverage.dat)."
fi
