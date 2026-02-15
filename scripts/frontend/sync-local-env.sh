#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SOURCE_ENV="${ROOT}/envs/deployed.local.env"
TARGET_ENV="${ROOT}/apps/nadswap/.env.local"

if [[ ! -f "${SOURCE_ENV}" ]]; then
  echo "[FAIL] Missing ${SOURCE_ENV}. Run ./scripts/deploy_local.sh first." >&2
  exit 1
fi

get_var() {
  local key="$1"
  local value
  value="$(awk -F'=' -v target="${key}" '$1 == target { sub(/^[ \t]+/, "", $2); print $2; exit }' "${SOURCE_ENV}")"
  echo "${value}"
}

require_var() {
  local key="$1"
  local value
  value="$(get_var "${key}")"
  if [[ -z "${value}" ]]; then
    echo "[FAIL] ${key} is missing in ${SOURCE_ENV}" >&2
    exit 1
  fi
  echo "${value}"
}

FACTORY="$(require_var FACTORY)"
ROUTER="$(require_var ROUTER)"
LENS_ADDRESS="$(require_var LENS_ADDRESS)"
WETH="$(require_var WETH)"
USDT="$(require_var USDT)"
NAD="$(require_var NAD)"
PAIR_USDT_NAD="$(require_var PAIR_USDT_NAD)"
ADMIN_ADDR="$(get_var ADMIN_ADDR)"
if [[ -z "${ADMIN_ADDR}" ]]; then
  ADMIN_ADDR="$(get_var PAIR_ADMIN)"
fi
CHAIN_ID="$(get_var LENS_CHAIN_ID)"
RPC_URL="$(get_var RPC_URL)"

if [[ -z "${CHAIN_ID}" ]]; then
  CHAIN_ID="31337"
fi
if [[ -z "${RPC_URL}" ]]; then
  RPC_URL="http://127.0.0.1:8545"
fi

cat > "${TARGET_ENV}" <<ENV
VITE_FACTORY=${FACTORY}
VITE_ROUTER=${ROUTER}
VITE_LENS_ADDRESS=${LENS_ADDRESS}
VITE_WETH=${WETH}
VITE_USDT=${USDT}
VITE_NAD=${NAD}
VITE_PAIR_USDT_NAD=${PAIR_USDT_NAD}
VITE_ADMIN_ADDRESSES=${ADMIN_ADDR}
VITE_CHAIN_ID=${CHAIN_ID}
VITE_RPC_URL=${RPC_URL}
ENV

echo "[PASS] Wrote ${TARGET_ENV}"
