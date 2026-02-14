#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RUNNERS="${ROOT}/scripts/runners"

SKIP_SLITHER=0
SKIP_UPSTREAM=0
SKIP_FORK=0
ONLY=""

usage() {
  cat <<'EOF'
Usage: ./run_all_tests.sh [options]

NadSwap V2 — 모든 검증 게이트를 한 번에 실행합니다.

Suites:
  gates       Strict-gate (build, slither, storage, unit/fuzz, invariant,
              math, traceability, migration, docs consistency)
  nightly     High-depth invariant (FOUNDRY_PROFILE=invariant-nightly)
  fork        Monad fork test suite (requires RPC)

Options:
  --only <suite>          Run a single suite: gates | fork
  --skip-slither          Skip Slither static-analysis gate.
  --skip-upstream-sync    Skip cloning/syncing upstream pinned refs.
  --skip-fork             Skip fork test suite (no RPC needed).
  -h, --help              Show this help.

Examples:
  ./run_all_tests.sh                          # Run everything
  ./run_all_tests.sh --skip-slither           # Skip Slither
  ./run_all_tests.sh --skip-fork              # Skip fork tests (no RPC)
  ./run_all_tests.sh --only gates             # Gates only
  ./run_all_tests.sh --only fork              # Fork only
EOF
}

log() {
  printf '\n\033[1;36m╔══════════════════════════════════════════════╗\033[0m\n'
  printf '\033[1;36m║  %s\033[0m\n' "$*"
  printf '\033[1;36m╚══════════════════════════════════════════════╝\033[0m\n\n'
}

log_step() {
  printf '\033[1;33m▸ %s\033[0m\n' "$*"
}

log_pass() {
  printf '\033[1;32m✅ %s\033[0m\n' "$*"
}

log_fail() {
  printf '\033[1;31m❌ %s\033[0m\n' "$*"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --only)
      ONLY="$2"
      shift 2
      ;;
    --skip-slither)
      SKIP_SLITHER=1
      shift
      ;;
    --skip-upstream-sync)
      SKIP_UPSTREAM=1
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

# ─── Dependency check ───
for tool in git python3 forge; do
  if ! command -v "${tool}" >/dev/null 2>&1; then
    log_fail "Missing required tool: ${tool}"
    echo "Run ./install_all_deps.sh first."
    exit 1
  fi
done

START_TIME=$(date +%s)

# ─── Build gate args ───
GATE_ARGS=()
[[ "${SKIP_SLITHER}" -eq 1 ]]  && GATE_ARGS+=("--skip-slither")
[[ "${SKIP_UPSTREAM}" -eq 1 ]] && GATE_ARGS+=("--skip-upstream-sync")

run_gates() {
  log "STRICT GATE + NIGHTLY INVARIANT"
  log_step "Running: scripts/runners/run_local_gates.sh ${GATE_ARGS[*]:-}"
  "${RUNNERS}/run_local_gates.sh" "${GATE_ARGS[@]:-}"
  log_pass "Strict gate + nightly invariant completed"
}

run_fork() {
  log "FORK TEST SUITE (Monad)"
  log_step "Running: scripts/runners/run_fork_tests.sh"
  "${RUNNERS}/run_fork_tests.sh"
  log_pass "Fork test suite completed"
}

# ─── Execute ───
FAILED=0

if [[ -n "${ONLY}" ]]; then
  case "${ONLY}" in
    gates)   run_gates   || FAILED=1 ;;
    fork)    run_fork    || FAILED=1 ;;
    *)
      log_fail "Unknown suite: ${ONLY}. Use: gates | fork"
      exit 1
      ;;
  esac
else
  run_gates || FAILED=1

  if [[ "${SKIP_FORK}" -eq 0 ]]; then
    run_fork || FAILED=1
  else
    log_step "Skipping fork tests (--skip-fork)"
  fi
fi

# ─── Summary ───
END_TIME=$(date +%s)
ELAPSED=$(( END_TIME - START_TIME ))
MINUTES=$(( ELAPSED / 60 ))
SECONDS=$(( ELAPSED % 60 ))

echo
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [[ "${FAILED}" -eq 0 ]]; then
  log_pass "ALL SUITES PASSED  (${MINUTES}m ${SECONDS}s)"
else
  log_fail "SOME SUITES FAILED  (${MINUTES}m ${SECONDS}s)"
fi
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

exit "${FAILED}"
