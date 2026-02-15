#!/usr/bin/env zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
LENS_DIR="${ROOT}/lens"
ENV_TEMPLATE="${ROOT}/envs/monad.testnet.env.sh"

if [[ -f "${ENV_TEMPLATE}" ]]; then
  source "${ENV_TEMPLATE}"
fi
# Unit tests should not inherit fork toggle from template env.
unset MONAD_FORK_ENABLED || true

SKIP_FORK=0
VERBOSITY="-v"
RPC_URL="${MONAD_RPC_URL:-}"
CHAIN_ID="${MONAD_CHAIN_ID:-}"
FORK_BLOCK="${MONAD_FORK_BLOCK:-}"
unset MONAD_FORK_ENABLED MONAD_RPC_URL MONAD_CHAIN_ID MONAD_FORK_BLOCK MONAD_FORK_FUZZ_RUNS || true

require_option_value() {
  local option="$1"
  local value="${2-}"
  if [[ -z "${value}" || "${value}" == -* ]]; then
    echo "[FAIL] ${option} requires a value." >&2
    usage
    exit 1
  fi
}

run_with_retry() {
  local max_attempts=3
  local attempt=1
  local rc=0

  while true; do
    "$@" && return 0
    rc=$?
    if [[ "${attempt}" -ge "${max_attempts}" ]]; then
      return "${rc}"
    fi
    echo "[WARN] command failed (attempt ${attempt}/${max_attempts}), retrying in 1s..."
    sleep 1
    attempt=$((attempt + 1))
  done
}

usage() {
  cat <<'USAGE'
Usage: ./scripts/runners/run_lens_tests.sh [options]

Options:
  --skip-fork            Skip Monad fork smoke tests.
  --rpc <url>            Override MONAD_RPC_URL.
  --chain-id <id>        Override MONAD_CHAIN_ID.
  --block <n>            Override MONAD_FORK_BLOCK.
  --latest               Set MONAD_FORK_BLOCK=0 (latest).
  -v|-vv|-vvv|-vvvv      Forge verbosity.
  -h, --help             Show this help.
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --skip-fork)
      SKIP_FORK=1
      shift
      ;;
    --rpc)
      require_option_value "--rpc" "${2-}"
      RPC_URL="$2"
      shift 2
      ;;
    --chain-id)
      require_option_value "--chain-id" "${2-}"
      CHAIN_ID="$2"
      shift 2
      ;;
    --block)
      require_option_value "--block" "${2-}"
      FORK_BLOCK="$2"
      shift 2
      ;;
    --latest)
      FORK_BLOCK=0
      shift
      ;;
    -v|-vv|-vvv|-vvvv|-vvvvv)
      VERBOSITY="$1"
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

echo "[RUN] lens unit tests (build included)"
cd "${LENS_DIR}"
run_with_retry env FOUNDRY_OFFLINE=true forge test --no-match-path "test/fork/**" ${VERBOSITY}

if [[ "${SKIP_FORK}" -eq 1 ]]; then
  echo "[SKIP] lens fork smoke tests (--skip-fork)"
  echo "[PASS] lens test suite completed"
  exit 0
fi

if [[ -z "${RPC_URL}" || -z "${CHAIN_ID}" || -z "${FORK_BLOCK}" ]]; then
  echo "[FAIL] Missing fork config. Source envs/monad.testnet.env.sh or set MONAD_* env vars." >&2
  exit 1
fi

export MONAD_FORK_ENABLED=1
export MONAD_RPC_URL="${RPC_URL}"
export MONAD_CHAIN_ID="${CHAIN_ID}"
export MONAD_FORK_BLOCK="${FORK_BLOCK}"

python3 "${ROOT}/scripts/fork/preflight_monad.py"

echo "[RUN] lens fork smoke tests"
run_with_retry forge test \
  --match-path "test/fork/**" \
  --fork-url "${MONAD_RPC_URL}" \
  --fork-block-number "${MONAD_FORK_BLOCK}" ${VERBOSITY}

echo "[PASS] lens test suite completed"
