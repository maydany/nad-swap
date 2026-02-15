#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LOG_DIR="${ROOT}/fork-logs"
ENV_TEMPLATE="${ROOT}/envs/monad.testnet.env.sh"
mkdir -p "${LOG_DIR}"

if [[ -f "${ENV_TEMPLATE}" ]]; then
  # shellcheck source=/dev/null
  source "${ENV_TEMPLATE}"
fi

RPC_URL="${MONAD_RPC_URL:-}"
CHAIN_ID="${MONAD_CHAIN_ID:-}"
FORK_BLOCK="${MONAD_FORK_BLOCK:-}"
FORK_FUZZ_RUNS="${MONAD_FORK_FUZZ_RUNS:-}"
VERBOSITY="-vv"
RUN_ALL=0

if [[ "${1-}" == "--" ]]; then
  shift
fi

require_option_value() {
  local option="$1"
  local value="${2-}"
  if [[ -z "${value}" || "${value}" == -* ]]; then
    echo "[FAIL] ${option} requires a value." >&2
    usage
    exit 1
  fi
}

usage() {
  cat <<'EOF'
Usage: ./scripts/runners/run_fork_tests.sh [options]

Options:
  --all                  Run full forge suite instead of fork-only subsets.
  --rpc <url>            Override MONAD_RPC_URL.
  --chain-id <id>        Override MONAD_CHAIN_ID.
  --block <n>            Override MONAD_FORK_BLOCK.
  --latest               Set MONAD_FORK_BLOCK=0 (latest).
  --fuzz-runs <n>        Override MONAD_FORK_FUZZ_RUNS.
  -v|-vv|-vvv|-vvvv      Forge verbosity.
  -h, --help             Show this help.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --)
      shift
      ;;
    --all)
      RUN_ALL=1
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
    --fuzz-runs)
      require_option_value "--fuzz-runs" "${2-}"
      FORK_FUZZ_RUNS="$2"
      shift 2
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

if [[ -z "${RPC_URL}" || -z "${CHAIN_ID}" || -z "${FORK_BLOCK}" || -z "${FORK_FUZZ_RUNS}" ]]; then
  echo "[FAIL] Missing fork config. Source envs/monad.testnet.env.sh or set MONAD_* env vars." >&2
  exit 1
fi

export MONAD_FORK_ENABLED=1
export MONAD_RPC_URL="${RPC_URL}"
export MONAD_CHAIN_ID="${CHAIN_ID}"
export MONAD_FORK_BLOCK="${FORK_BLOCK}"
export MONAD_FORK_FUZZ_RUNS="${FORK_FUZZ_RUNS}"

python3 "${ROOT}/scripts/fork/preflight_monad.py" | tee "${LOG_DIR}/00-preflight.log"

(
  cd "${ROOT}/protocol"
  if [[ "${RUN_ALL}" -eq 1 ]]; then
    forge test ${VERBOSITY} | tee "${LOG_DIR}/20-all.log"
  else
    forge build | tee "${LOG_DIR}/10-build.log"
    forge test \
      --match-path "test/fork/core/**/*.t.sol" \
      --fork-url "${MONAD_RPC_URL}" \
      --fork-block-number "${MONAD_FORK_BLOCK}" ${VERBOSITY} | tee "${LOG_DIR}/20-core.log"

    forge test \
      --match-path "test/fork/periphery/**/*.t.sol" \
      --fork-url "${MONAD_RPC_URL}" \
      --fork-block-number "${MONAD_FORK_BLOCK}" ${VERBOSITY} | tee "${LOG_DIR}/30-periphery.log"

    forge test \
      --match-contract ForkFuzzLiteTest \
      --fork-url "${MONAD_RPC_URL}" \
      --fork-block-number "${MONAD_FORK_BLOCK}" \
      --fuzz-runs "${MONAD_FORK_FUZZ_RUNS}" ${VERBOSITY} | tee "${LOG_DIR}/40-fuzz-lite.log"
  fi
)

echo "[PASS] Fork suite completed. Logs at ${LOG_DIR}"
