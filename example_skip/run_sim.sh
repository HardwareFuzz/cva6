#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "${SCRIPT_DIR}/.." && pwd)
ELF="${SCRIPT_DIR}/skip_trap.elf"
TRACE_DIR_DEFAULT="${SCRIPT_DIR}/logs"
TRACE_DIR="${TRACE_LOG_DIR:-${TRACE_DIR_DEFAULT}}"

if [[ -z "${RISCV:-}" ]]; then
  echo "[example_skip] 请先设置 RISCV 环境变量" >&2
  exit 1
fi

if [[ ! -f "${ELF}" ]]; then
  echo "[example_skip] 构建 ELF..."
  make -C "${SCRIPT_DIR}" >/dev/null
fi

cd "${REPO_ROOT}"
make verilate >/dev/null
TOHOST_ADDR=$("${RISCV}/bin/riscv64-unknown-elf-nm" -B "${ELF}" | awk '$3=="tohost" {print $1}')
if [[ -z "${TOHOST_ADDR}" ]]; then
  echo "[example_skip] 未找到 tohost 符号" >&2
  exit 1
fi

mkdir -p "${TRACE_DIR}"
rm -f "${TRACE_DIR}/trace_rvfi_hart_"*.dasm "${TRACE_DIR}/trace_hart_"*.dasm "${TRACE_DIR}/iti.trace" 2>/dev/null || true
echo "[example_skip] 日志将写入: ${TRACE_DIR}"

work-ver/Variane_testharness "${ELF}" +elf_file="${ELF}" +tohost_addr=${TOHOST_ADDR} +trace_log_dir=${TRACE_DIR} "$@"
