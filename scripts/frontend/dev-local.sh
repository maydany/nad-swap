#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

ANVIL_PID=""

cleanup() {
  if [[ -n "${ANVIL_PID}" ]] && kill -0 "${ANVIL_PID}" 2>/dev/null; then
    kill "${ANVIL_PID}" 2>/dev/null || true
    echo "[INFO] Stopped Anvil (PID: ${ANVIL_PID})"
  fi
}

trap cleanup EXIT INT TERM

cd "${ROOT}"

# deploy_local.sh already replaces any stale process on :8545 before deploying.
./deploy_local.sh --detach-anvil

ANVIL_PID="$(lsof -ti :8545 -sTCP:LISTEN | head -n 1 || true)"
if [[ -z "${ANVIL_PID}" ]]; then
  echo "[FAIL] Anvil is not listening on :8545 after deploy_local.sh" >&2
  exit 1
fi

pnpm env:sync:nadswap
pnpm --filter @nadswap/nadswap dev
