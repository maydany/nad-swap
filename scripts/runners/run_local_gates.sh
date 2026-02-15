#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PROTOCOL_DIR="${ROOT}/protocol"
UPSTREAM_DIR="${ROOT}/upstream"
UPSTREAM_CORE_DIR="${UPSTREAM_DIR}/v2-core"
UPSTREAM_PERIPHERY_DIR="${UPSTREAM_DIR}/v2-periphery"

EXPECTED_CORE_SHA="ee547b17853e71ed4e0101ccfd52e70d5acded58"
EXPECTED_PERIPHERY_SHA="0335e8f7e1bd1e8d8329fd300aea2ef2f36dd19f"

FOUNDRY_OFFLINE="${FOUNDRY_OFFLINE:-true}"
SKIP_SLITHER=0
SKIP_UPSTREAM_SYNC=0
SKIP_FORK=0

usage() {
  cat <<'EOF'
Usage: ./scripts/runners/run_local_gates.sh [options]

Runs NadSwap local verification gates in one command.
Nightly high-depth invariant is mandatory; fork suite runs unless skipped.
Docs metrics rendering and consistency gates are included.

Options:
  --skip-slither            Skip Slither static-analysis gate.
  --skip-upstream-sync      Skip cloning/syncing upstream pinned refs.
  --skip-fork               Skip fork test suite in this runner.
  -h, --help                Show this help.

Examples:
  ./scripts/runners/run_local_gates.sh
  MONAD_FORK_BLOCK=12700000 ./scripts/runners/run_local_gates.sh
EOF
}

log() {
  printf '[%s] %s\n' "$(date +'%H:%M:%S')" "$*"
}

run_cmd() {
  log "RUN: $*"
  "$@"
}

ensure_tool() {
  local tool="$1"
  if ! command -v "${tool}" >/dev/null 2>&1; then
    echo "[FAIL] Missing required tool: ${tool}" >&2
    exit 1
  fi
}

sync_repo_to_sha() {
  local dir="$1"
  local url="$2"
  local sha="$3"

  mkdir -p "${UPSTREAM_DIR}"

  if [[ ! -d "${dir}/.git" ]]; then
    run_cmd git clone "${url}" "${dir}"
  fi

  if ! git -C "${dir}" rev-parse --verify "${sha}^{commit}" >/dev/null 2>&1; then
    run_cmd git -C "${dir}" fetch origin "${sha}" --depth=1
  fi
  run_cmd git -C "${dir}" checkout "${sha}"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --skip-slither)
      SKIP_SLITHER=1
      shift
      ;;
    --skip-upstream-sync)
      SKIP_UPSTREAM_SYNC=1
      shift
      ;;
    --skip-fork)
      SKIP_FORK=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "[FAIL] Unknown option: $1" >&2
      usage
      exit 1
      ;;
  esac
done

ensure_tool git
ensure_tool python3
ensure_tool forge

if [[ "${SKIP_UPSTREAM_SYNC}" -eq 0 ]]; then
  log "Syncing upstream pinned refs..."
  sync_repo_to_sha "${UPSTREAM_CORE_DIR}" "https://github.com/Uniswap/v2-core.git" "${EXPECTED_CORE_SHA}"
  sync_repo_to_sha "${UPSTREAM_PERIPHERY_DIR}" "https://github.com/Uniswap/v2-periphery.git" "${EXPECTED_PERIPHERY_SHA}"
else
  log "Skipping upstream sync by option."
fi

log "Build"
(
  cd "${PROTOCOL_DIR}"
  FOUNDRY_OFFLINE="${FOUNDRY_OFFLINE}" forge build
)

if [[ "${SKIP_SLITHER}" -eq 0 ]]; then
  log "Slither Static Analysis Gate"
  python3 "${ROOT}/scripts/gates/check_slither_gate.py"
else
  log "Skipping Slither gate by option."
fi

log "Storage Layout Gate"
python3 "${ROOT}/scripts/gates/check_storage_layout.py"

log "P0 Smoke Gate (swap/tax guard paths)"
(
  cd "${PROTOCOL_DIR}"
  FOUNDRY_OFFLINE="${FOUNDRY_OFFLINE}" forge test --match-path "test/core/PairSwapGuards.t.sol"
  FOUNDRY_OFFLINE="${FOUNDRY_OFFLINE}" forge test --match-path "test/core/PairFlashQuote.t.sol"
)

log "Lightweight Invariant Gate"
(
  cd "${PROTOCOL_DIR}"
  FOUNDRY_OFFLINE="${FOUNDRY_OFFLINE}" forge test --match-path "test/invariant/**"
)

log "Unit/Fuzz/Regression Tests (non-fork, non-stateful-invariant)"
(
  cd "${PROTOCOL_DIR}"
  FOUNDRY_OFFLINE="${FOUNDRY_OFFLINE}" forge test --no-match-path "test/{fork,invariant}/**"
)

log "Nightly High-Depth Invariant Gate"
mkdir -p "${ROOT}/invariant-logs"
NIGHTLY_LOG="${ROOT}/invariant-logs/local-nightly-invariant-$(date +%Y%m%d-%H%M%S).log"
(
  cd "${PROTOCOL_DIR}"
  FOUNDRY_OFFLINE="${FOUNDRY_OFFLINE}" FOUNDRY_PROFILE=invariant-nightly forge test \
    --match-path "test/invariant/**" \
    -vv | tee "${NIGHTLY_LOG}"
)

log "Nightly Large-Domain K/Overflow Fuzz Gate"
(
  cd "${PROTOCOL_DIR}"
  FOUNDRY_OFFLINE="${FOUNDRY_OFFLINE}" FOUNDRY_PROFILE=invariant-nightly forge test \
    --match-path "test/core/PairKOverflowDomain.t.sol" \
    --fuzz-runs 1024 \
    -vv | tee -a "${NIGHTLY_LOG}"
)
log "Nightly invariant log saved: ${NIGHTLY_LOG}"

log "Math Consistency Gate"
python3 "${ROOT}/scripts/gates/check_math_consistency.py"

log "Traceability Gate"
python3 "${ROOT}/scripts/gates/check_traceability.py"

log "Migration Checklist Gate"
python3 "${ROOT}/scripts/gates/check_migration_signoff.py"

if [[ "${SKIP_FORK}" -eq 0 ]]; then
  log "Fork Test Suite"
  "${ROOT}/scripts/runners/run_fork_tests.sh"
else
  log "Skipping fork suite by option."
fi

log "Collect Verification Metrics"
python3 "${ROOT}/scripts/reports/collect_verification_metrics.py" \
  --output "${ROOT}/docs/reports/NADSWAP_V2_VERIFICATION_METRICS.json"

log "Render Verification Reports"
python3 "${ROOT}/scripts/reports/render_verification_reports.py" \
  --metrics "${ROOT}/docs/reports/NADSWAP_V2_VERIFICATION_METRICS.json"

log "Docs Symbol Refs Gate"
python3 "${ROOT}/scripts/gates/check_docs_symbol_refs.py"

log "Docs Consistency Gate"
python3 "${ROOT}/scripts/gates/check_docs_consistency.py"

log "PASS: Local gate run completed."
