#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────
#  deploy_local.sh — NadSwap one-click local deployment
#  Usage: ./deploy_local.sh
# ─────────────────────────────────────────────────────────
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROTOCOL_DIR="${ROOT}/protocol"
DEPLOY_DIR="${ROOT}/envs"
ENV_FILE="${DEPLOY_DIR}/local.env"

# ── Anvil default account #0 ────────────────────────────
[[ -f "${ENV_FILE}" ]] || { echo "[FAIL] Missing env file: ${ENV_FILE}" >&2; exit 1; }
source "${ENV_FILE}"

[[ -n "${DEPLOYER_PK:-}" ]] || { echo "[FAIL] DEPLOYER_PK is missing in ${ENV_FILE}" >&2; exit 1; }
[[ -n "${DEPLOYER_ADDR:-}" ]] || { echo "[FAIL] DEPLOYER_ADDR is missing in ${ENV_FILE}" >&2; exit 1; }

RPC_URL="http://127.0.0.1:8545"

# ── Helpers ──────────────────────────────────────────────
log()  { printf '\n\033[1;36m[%s] %s\033[0m\n' "$(date +'%H:%M:%S')" "$*"; }
fail() { printf '\033[1;31m[FAIL] %s\033[0m\n' "$*" >&2; exit 1; }

ensure_tool() {
  command -v "$1" >/dev/null 2>&1 || fail "Missing required tool: $1"
}

# Extract deployed address from forge create output
extract_addr() {
  grep -oE '0x[0-9a-fA-F]{40}' | head -1
}

# forge create wrapper
deploy() {
  local contract="$1"
  shift
  forge create "${contract}" \
    --rpc-url "${RPC_URL}" \
    --private-key "${DEPLOYER_PK}" \
    --root "${PROTOCOL_DIR}" \
    "$@" 2>&1
}

# cast send wrapper
send() {
  cast send "$@" \
    --rpc-url "${RPC_URL}" \
    --private-key "${DEPLOYER_PK}" 2>&1
}

# ── Preflight ────────────────────────────────────────────
ensure_tool forge
ensure_tool cast
ensure_tool anvil

# ── Kill any existing Anvil ──────────────────────────────
if lsof -i :8545 -sTCP:LISTEN >/dev/null 2>&1; then
  log "Port 8545 already in use — killing existing process..."
  lsof -ti :8545 | xargs kill -9 2>/dev/null || true
  sleep 1
fi

# ── Start Anvil ──────────────────────────────────────────
log "Starting Anvil..."
anvil --silent &
ANVIL_PID=$!
sleep 2

if ! kill -0 "${ANVIL_PID}" 2>/dev/null; then
  fail "Anvil failed to start"
fi
log "Anvil running (PID: ${ANVIL_PID})"

# Cleanup on exit
cleanup() {
  if kill -0 "${ANVIL_PID}" 2>/dev/null; then
    kill "${ANVIL_PID}" 2>/dev/null || true
    log "Anvil stopped."
  fi
}
trap cleanup EXIT

# ── Build ────────────────────────────────────────────────
log "Building contracts..."
(cd "${PROTOCOL_DIR}" && forge build --force)

# ── Deploy MockWETH ──────────────────────────────────────
log "Deploying MockWETH..."
WETH_OUT=$(deploy "test/helpers/MockWETH.sol:MockWETH")
WETH=$(echo "${WETH_OUT}" | extract_addr)
log "  WETH = ${WETH}"

# ── Deploy Mock Tokens ───────────────────────────────────
log "Deploying USDT (quote token)..."
USDT_OUT=$(deploy "test/helpers/MockERC20.sol:MockERC20" --constructor-args "Tether USD" "USDT" 18)
USDT=$(echo "${USDT_OUT}" | extract_addr)
log "  USDT = ${USDT}"

log "Deploying NAD (base token)..."
NAD_OUT=$(deploy "test/helpers/MockERC20.sol:MockERC20" --constructor-args "Nad Token" "NAD" 18)
NAD=$(echo "${NAD_OUT}" | extract_addr)
log "  NAD  = ${NAD}"

# ── Deploy Factory ───────────────────────────────────────
log "Deploying UniswapV2Factory..."
FACTORY_OUT=$(deploy "src/core/UniswapV2Factory.sol:UniswapV2Factory" \
  --constructor-args "${DEPLOYER_ADDR}" "${DEPLOYER_ADDR}")
FACTORY=$(echo "${FACTORY_OUT}" | extract_addr)
log "  FACTORY = ${FACTORY}"

# ── Configure Factory ────────────────────────────────────
log "Setting USDT as quote token..."
send "${FACTORY}" "setQuoteToken(address,bool)" "${USDT}" true

log "Setting NAD as supported base token..."
send "${FACTORY}" "setBaseTokenSupported(address,bool)" "${NAD}" true

# ── Create Pair ──────────────────────────────────────────
log "Creating USDT/NAD pair (0% tax)..."
PAIR_TX=$(send "${FACTORY}" "createPair(address,address,uint16,uint16,address)" \
  "${USDT}" "${NAD}" 0 0 "${DEPLOYER_ADDR}")
PAIR=$(cast call "${FACTORY}" "getPair(address,address)(address)" "${USDT}" "${NAD}" --rpc-url "${RPC_URL}")
log "  PAIR = ${PAIR}"

# ── Deploy Router ────────────────────────────────────────
log "Deploying UniswapV2Router02..."
ROUTER_OUT=$(deploy "src/periphery/UniswapV2Router02.sol:UniswapV2Router02" \
  --constructor-args "${FACTORY}" "${WETH}")
ROUTER=$(echo "${ROUTER_OUT}" | extract_addr)
log "  ROUTER = ${ROUTER}"

# ── Add Initial Liquidity ────────────────────────────────
LIQUIDITY="1000000000000000000000000"  # 1,000,000 ether (1e24)

log "Minting tokens..."
send "${USDT}" "mint(address,uint256)" "${DEPLOYER_ADDR}" "${LIQUIDITY}"
send "${NAD}"  "mint(address,uint256)" "${DEPLOYER_ADDR}" "${LIQUIDITY}"

log "Transferring tokens to Pair..."
send "${USDT}" "transfer(address,uint256)" "${PAIR}" "${LIQUIDITY}"
send "${NAD}"  "transfer(address,uint256)" "${PAIR}" "${LIQUIDITY}"

log "Minting LP tokens..."
send "${PAIR}" "mint(address)" "${DEPLOYER_ADDR}"

# ── Verification ─────────────────────────────────────────
log "Verifying deployment..."

PAIRS_LEN=$(cast call "${FACTORY}" "allPairsLength()(uint256)" --rpc-url "${RPC_URL}")
ROUTER_FACTORY=$(cast call "${ROUTER}" "factory()(address)" --rpc-url "${RPC_URL}")
LP_BAL=$(cast call "${PAIR}" "balanceOf(address)(uint256)" "${DEPLOYER_ADDR}" --rpc-url "${RPC_URL}")

echo ""
if [[ "${PAIRS_LEN}" == "1" ]]; then
  echo "  ✅ Factory.allPairsLength() = ${PAIRS_LEN}"
else
  echo "  ❌ Factory.allPairsLength() = ${PAIRS_LEN} (expected 1)"
fi

ROUTER_FACTORY_LOWER=$(echo "${ROUTER_FACTORY}" | tr '[:upper:]' '[:lower:]')
FACTORY_LOWER=$(echo "${FACTORY}" | tr '[:upper:]' '[:lower:]')
if [[ "${ROUTER_FACTORY_LOWER}" == "${FACTORY_LOWER}" ]]; then
  echo "  ✅ Router.factory() matches Factory"
else
  echo "  ❌ Router.factory() mismatch: ${ROUTER_FACTORY} vs ${FACTORY}"
fi

if [[ "${LP_BAL}" != "0" ]]; then
  echo "  ✅ Deployer LP balance = ${LP_BAL}"
else
  echo "  ❌ Deployer LP balance is 0"
fi

# ── Save Addresses ───────────────────────────────────────
mkdir -p "${DEPLOY_DIR}"
cat > "${DEPLOY_DIR}/deployed.local.env" <<EOF
# NadSwap Local Deployment — $(date +'%Y-%m-%d %H:%M:%S')
# Chain: Anvil (localhost:8545, chainId=31337)

WETH=${WETH}
USDT=${USDT}
NAD=${NAD}
FACTORY=${FACTORY}
ROUTER=${ROUTER}
PAIR_USDT_NAD=${PAIR}
EOF

# ── Summary ──────────────────────────────────────────────
echo ""
echo "═══════════════════════════════════════════════════"
echo "  NadSwap Local Deployment — Complete"
echo "═══════════════════════════════════════════════════"
echo "  WETH     = ${WETH}"
echo "  USDT     = ${USDT}"
echo "  NAD      = ${NAD}"
echo "  FACTORY  = ${FACTORY}"
echo "  ROUTER   = ${ROUTER}"
echo "  PAIR     = ${PAIR}"
echo "═══════════════════════════════════════════════════"
echo "  Addresses saved to: ${DEPLOY_DIR}/deployed.local.env"
echo "  Anvil running on ${RPC_URL} (PID: ${ANVIL_PID})"
echo ""
echo "  Press Ctrl+C to stop Anvil."
echo "═══════════════════════════════════════════════════"

# ── Keep Anvil alive ─────────────────────────────────────
trap - EXIT  # Remove cleanup trap so Anvil stays running
wait "${ANVIL_PID}"
