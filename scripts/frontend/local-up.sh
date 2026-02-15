#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ANVIL_PID=""

log_step() {
  printf '[STEP] %s\n' "$*"
}

cleanup() {
  if [[ -n "${ANVIL_PID}" ]] && kill -0 "${ANVIL_PID}" 2>/dev/null; then
    kill "${ANVIL_PID}" 2>/dev/null || true
    printf '[INFO] Stopped Anvil (PID: %s)\n' "${ANVIL_PID}"
  fi
}

trap cleanup EXIT INT TERM

cd "${ROOT}"

log_step "Deploying local core + lens (detached anvil)"
./scripts/deploy_local.sh --detach-anvil

ANVIL_PID="$(lsof -ti :8545 -sTCP:LISTEN | head -n 1 || true)"
if [[ -z "${ANVIL_PID}" ]]; then
  echo "[FAIL] Anvil is not listening on :8545 after ./scripts/deploy_local.sh --detach-anvil" >&2
  exit 1
fi

log_step "Running local validation (gates + lens unit, no fork, no report writes)"
pnpm test:local

log_step "Syncing frontend env"
pnpm env:sync:nadswap

log_step "Starting frontend dev server"
pnpm --filter @nadswap/nadswap dev
