#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────
#  deploy_local.sh — NadSwap one-click local deployment
#  Usage: ./deploy_local.sh
# ─────────────────────────────────────────────────────────
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROTOCOL_DIR="${ROOT}/protocol"
LENS_DIR="${ROOT}/lens"
DEPLOY_DIR="${ROOT}/envs"
ENV_FILE="${DEPLOY_DIR}/local.env"
LOCAL_DEPLOY_FILE="${DEPLOY_DIR}/deployed.local.env"
# Temporary file produced by lens/script/DeployLens.s.sol.
LENS_ENV_FILE="${DEPLOY_DIR}/deployed.lens.env"

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
  local out="$1"
  local addr
  addr=$(echo "${out}" | awk '/Deployed to:/{print $3}' | tail -1)
  if [[ -z "${addr}" ]]; then
    # Fallback: use the last 20-byte hex in output (avoid picking Deployer line first).
    addr=$(echo "${out}" | grep -oE '0x[0-9a-fA-F]{40}' | tail -1 || true)
  fi
  echo "${addr}"
}

require_addr() {
  local label="$1"
  local addr="$2"
  [[ "${addr}" =~ ^0x[0-9a-fA-F]{40}$ ]] || fail "Could not parse ${label} deployment address"
}

lower() {
  echo "$1" | tr '[:upper:]' '[:lower:]'
}

normalize_cast_output() {
  echo "$1" | tr '[:upper:]' '[:lower:]' | tr -d '[:space:](),[]'
}

assert_cast_contains() {
  local label="$1"
  local output="$2"
  local expected="$3"
  local normalized_output
  local normalized_expected

  normalized_output="$(normalize_cast_output "${output}")"
  normalized_expected="$(normalize_cast_output "${expected}")"

  [[ "${normalized_output}" == *"${normalized_expected}"* ]] \
    || fail "${label} check failed. Output: ${output}"
}

# forge create wrapper
deploy() {
  local contract="$1"
  shift
  forge create "${contract}" \
    --broadcast \
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
[[ -d "${LENS_DIR}" ]] || fail "Missing lens directory: ${LENS_DIR}"

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
WETH=$(extract_addr "${WETH_OUT}")
require_addr "MockWETH" "${WETH}"
log "  WETH = ${WETH}"

# ── Deploy Mock Tokens ───────────────────────────────────
log "Deploying USDT (quote token)..."
USDT_OUT=$(deploy "test/helpers/MockERC20.sol:MockERC20" --constructor-args "Tether USD" "USDT" 18)
USDT=$(extract_addr "${USDT_OUT}")
require_addr "USDT" "${USDT}"
log "  USDT = ${USDT}"

log "Deploying NAD (base token)..."
NAD_OUT=$(deploy "test/helpers/MockERC20.sol:MockERC20" --constructor-args "Nad Token" "NAD" 18)
NAD=$(extract_addr "${NAD_OUT}")
require_addr "NAD" "${NAD}"
log "  NAD  = ${NAD}"

# ── Deploy Factory ───────────────────────────────────────
log "Deploying UniswapV2Factory..."
FACTORY_OUT=$(deploy "src/core/NadSwapV2Factory.sol:UniswapV2Factory" \
  --constructor-args "${DEPLOYER_ADDR}")
FACTORY=$(extract_addr "${FACTORY_OUT}")
require_addr "Factory" "${FACTORY}"
log "  FACTORY = ${FACTORY}"

# ── Configure Factory ────────────────────────────────────
log "Setting USDT as quote token..."
send "${FACTORY}" "setQuoteToken(address,bool)" "${USDT}" true

# ── Create Pair ──────────────────────────────────────────
log "Creating USDT/NAD pair (0% tax)..."
send "${FACTORY}" "createPair(address,address,uint16,uint16,address)" \
  "${USDT}" "${NAD}" 0 0 "${DEPLOYER_ADDR}"
PAIR=$(cast call "${FACTORY}" "getPair(address,address)(address)" "${USDT}" "${NAD}" --rpc-url "${RPC_URL}")
log "  PAIR = ${PAIR}"

# ── Deploy Router ────────────────────────────────────────
log "Deploying UniswapV2Router02..."
ROUTER_OUT=$(deploy "src/periphery/NadSwapV2Router02.sol:UniswapV2Router02" \
  --constructor-args "${FACTORY}" "${WETH}")
ROUTER=$(extract_addr "${ROUTER_OUT}")
require_addr "Router" "${ROUTER}"
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

# ── Build & Deploy Lens ──────────────────────────────────
log "Building Lens contracts..."
(cd "${LENS_DIR}" && forge build --force)

log "Deploying NadSwapLensV1_1..."
rm -f "${LENS_ENV_FILE}"
(
  cd "${LENS_DIR}" && \
  LENS_FACTORY="${FACTORY}" \
  LENS_ROUTER="${ROUTER}" \
  forge script script/DeployLens.s.sol:DeployLensScript \
    --rpc-url "${RPC_URL}" \
    --private-key "${DEPLOYER_PK}" \
    --broadcast
)

[[ -f "${LENS_ENV_FILE}" ]] || fail "Missing Lens deployment output: ${LENS_ENV_FILE}"
# shellcheck source=/dev/null
source "${LENS_ENV_FILE}"

[[ -n "${LENS_ADDRESS:-}" ]] || fail "LENS_ADDRESS missing in ${LENS_ENV_FILE}"
[[ -n "${LENS_FACTORY:-}" ]] || fail "LENS_FACTORY missing in ${LENS_ENV_FILE}"
[[ -n "${LENS_ROUTER:-}" ]] || fail "LENS_ROUTER missing in ${LENS_ENV_FILE}"
[[ -n "${LENS_CHAIN_ID:-}" ]] || fail "LENS_CHAIN_ID missing in ${LENS_ENV_FILE}"

require_addr "Lens" "${LENS_ADDRESS}"
require_addr "Lens factory" "${LENS_FACTORY}"
require_addr "Lens router" "${LENS_ROUTER}"
[[ "${LENS_CHAIN_ID}" =~ ^[0-9]+$ ]] || fail "Invalid LENS_CHAIN_ID in ${LENS_ENV_FILE}: ${LENS_CHAIN_ID}"

if [[ "$(lower "${LENS_FACTORY}")" != "$(lower "${FACTORY}")" ]]; then
  fail "LENS_FACTORY mismatch: ${LENS_FACTORY} vs ${FACTORY}"
fi

if [[ "$(lower "${LENS_ROUTER}")" != "$(lower "${ROUTER}")" ]]; then
  fail "LENS_ROUTER mismatch: ${LENS_ROUTER} vs ${ROUTER}"
fi

if [[ "${LENS_CHAIN_ID}" != "31337" ]]; then
  fail "LENS_CHAIN_ID mismatch: ${LENS_CHAIN_ID} (expected 31337)"
fi

log "Verifying Lens read paths..."

LENS_FACTORY_ONCHAIN=$(cast call "${LENS_ADDRESS}" "factory()(address)" --rpc-url "${RPC_URL}")
if [[ "$(lower "${LENS_FACTORY_ONCHAIN}")" != "$(lower "${FACTORY}")" ]]; then
  fail "Lens.factory() mismatch: ${LENS_FACTORY_ONCHAIN} vs ${FACTORY}"
fi
echo "  ✅ Lens.factory() matches Factory"

LENS_ROUTER_ONCHAIN=$(cast call "${LENS_ADDRESS}" "router()(address)" --rpc-url "${RPC_URL}")
if [[ "$(lower "${LENS_ROUTER_ONCHAIN}")" != "$(lower "${ROUTER}")" ]]; then
  fail "Lens.router() mismatch: ${LENS_ROUTER_ONCHAIN} vs ${ROUTER}"
fi
echo "  ✅ Lens.router() matches Router"

LENS_GET_PAIR=$(cast call "${LENS_ADDRESS}" "getPair(address,address)(address,bool)" "${USDT}" "${NAD}" --rpc-url "${RPC_URL}")
assert_cast_contains "Lens.getPair(address,address) pair" "${LENS_GET_PAIR}" "${PAIR}"
assert_cast_contains "Lens.getPair(address,address) valid flag" "${LENS_GET_PAIR}" "true"
echo "  ✅ Lens.getPair() returns expected pair + valid=true"

LENS_PAIRS_LEN=$(cast call "${LENS_ADDRESS}" "getPairsLength()(bool,uint256)" --rpc-url "${RPC_URL}")
assert_cast_contains "Lens.getPairsLength() ok flag" "${LENS_PAIRS_LEN}" "true"
assert_cast_contains "Lens.getPairsLength() value" "${LENS_PAIRS_LEN}" "1"
echo "  ✅ Lens.getPairsLength() returns (true, 1)"

LENS_PAIRS_PAGE=$(cast call "${LENS_ADDRESS}" "getPairsPage(uint256,uint256)(bool,address[])" 0 1 --rpc-url "${RPC_URL}")
assert_cast_contains "Lens.getPairsPage() ok flag" "${LENS_PAIRS_PAGE}" "true"
assert_cast_contains "Lens.getPairsPage() pair value" "${LENS_PAIRS_PAGE}" "${PAIR}"
echo "  ✅ Lens.getPairsPage(0,1) returns expected pair"

if ! cast call "${LENS_ADDRESS}" "getPairView(address,address)" "${PAIR}" "${DEPLOYER_ADDR}" --rpc-url "${RPC_URL}" >/dev/null; then
  fail "Lens.getPairView(address,address) reverted"
fi
echo "  ✅ Lens.getPairView() call succeeded"

# ── Save Addresses ───────────────────────────────────────
mkdir -p "${DEPLOY_DIR}"
cat > "${LOCAL_DEPLOY_FILE}" <<EOF
# NadSwap Local Deployment — $(date +'%Y-%m-%d %H:%M:%S')
# Chain: Anvil (localhost:8545, chainId=31337)

WETH=${WETH}
USDT=${USDT}
NAD=${NAD}
FACTORY=${FACTORY}
ROUTER=${ROUTER}
PAIR_USDT_NAD=${PAIR}
LENS_ADDRESS=${LENS_ADDRESS}
LENS_FACTORY=${LENS_FACTORY}
LENS_ROUTER=${LENS_ROUTER}
LENS_CHAIN_ID=${LENS_CHAIN_ID}
EOF

# Keep integrated local output as the single source of truth for deploy_local.sh users.
rm -f "${LENS_ENV_FILE}"

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
echo "  LENS     = ${LENS_ADDRESS}"
echo "═══════════════════════════════════════════════════"
echo "  Addresses saved to: ${LOCAL_DEPLOY_FILE}"
echo "  Anvil running on ${RPC_URL} (PID: ${ANVIL_PID})"
echo ""
echo "  Press Ctrl+C to stop Anvil."
echo "═══════════════════════════════════════════════════"

# ── Keep Anvil alive ─────────────────────────────────────
trap - EXIT  # Remove cleanup trap so Anvil stays running
wait "${ANVIL_PID}"
