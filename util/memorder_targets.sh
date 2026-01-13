#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "${SCRIPT_DIR}/.." && pwd)

TARGETS=(
  cv64a6_full_sv39_memorder_rvwmo
  cv64a6_full_sv39_memorder_tso
  cv64a6_full_sv39_memorder_sc
)

usage() {
  cat <<'USAGE'
Usage: util/memorder_targets.sh [list|build] [targets...]

Commands:
  list   Print memorder target names (one per line).
  build  Build memorder targets with `make verilate target=<target>`.
         If no targets are provided, build all.

Environment:
  NUM_JOBS  Passed through to make (controls -j).
  MAKE_ARGS Extra arguments appended to make (optional).
USAGE
}

cmd="${1:-list}"
case "${cmd}" in
  list)
    printf "%s\n" "${TARGETS[@]}"
    ;;
  build)
    shift || true
    if [[ $# -eq 0 ]]; then
      set -- "${TARGETS[@]}"
    fi
    for target in "$@"; do
      echo "[memorder] build ${target}"
      (cd "${REPO_ROOT}" && make verilate target="${target}" ${NUM_JOBS:+NUM_JOBS="$NUM_JOBS"} ${MAKE_ARGS:-})
    done
    ;;
  -h|--help)
    usage
    ;;
  *)
    echo "Unknown command: ${cmd}" >&2
    usage
    exit 2
    ;;
esac
