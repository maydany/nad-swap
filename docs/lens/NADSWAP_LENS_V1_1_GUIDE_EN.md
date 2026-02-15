# NadSwap Lens V1.1 Guide (EN)

This is the single-source guide for NadSwap Lens V1.1. It is organized as:
- Quickstart for first successful call in 5-10 minutes
- Cookbook for production usage scenarios
- API reference with response contracts and failure modes

Related docs:
- Deployment: [NADSWAP_LENS_V1_1_DEPLOYMENT.md](./NADSWAP_LENS_V1_1_DEPLOYMENT.md)
- Docs index: [README.md](./README.md)

## 0. Audience & Scope
### Audience
- Frontend engineers integrating NadSwap pair data.
- Backend/indexer engineers building read paths.
- QA/ops engineers validating behavior across normal and degraded states.

### Scope
- Covers Lens V1.1 read functions only.
- Covers success responses, degraded responses, and revert/error behavior.
- Covers pagination and RPC retry strategy for real operation.

### Out of scope
- No write flow (Lens is read-only).
- No GraphQL query/mutation examples.

### GraphQL note
NadSwap Lens is an EVM contract API, not GraphQL. Equivalent guidance is provided via:
- Solidity function signatures
- `cast call` examples
- TypeScript examples
- Offset pagination (`start`, `count`) behavior

### Version baseline
- Contract target: `lens/src/NadSwapLensV1_1.sol`
- Contract version: V1.1
- Compiler: `solc 0.8.25`
- EVM target: `cancun`

<a id="quickstart"></a>
## 1. Quickstart (5-10 minutes)
### 1.1 Prerequisites
- `forge` and `cast` installed.
- Local environment file exists: `envs/local.env`.

### 1.2 Deploy local core + lens
```bash
cd /Users/sunghoon-air/Desktop/projects.nosync/nad-swap
./deploy_local.sh
```

Expected output summary includes:
- `WETH`, `USDT`, `NAD`, `FACTORY`, `ROUTER`, `PAIR`
- `LENS`
- `Addresses saved to: envs/deployed.local.env`

### 1.3 Load deployment variables
```bash
cd /Users/sunghoon-air/Desktop/projects.nosync/nad-swap
set -a
source envs/deployed.local.env
set +a
```

### 1.4 First call (cast)
```bash
cast call "$LENS_ADDRESS" "getPair(address,address)(address,bool)" "$USDT" "$NAD" --rpc-url "http://127.0.0.1:8545"
```

Expected success response:
```text
(0xYourPairAddress, true)
```

### 1.5 First call (TypeScript, ethers)
```ts
import { Contract, JsonRpcProvider } from "ethers";

const provider = new JsonRpcProvider("http://127.0.0.1:8545");

const lensAbi = [
  "function getPair(address tokenA, address tokenB) view returns (address pair, bool isValidPair)"
];

const lens = new Contract(process.env.LENS_ADDRESS!, lensAbi, provider);
const [pair, isValidPair] = await lens.getPair(process.env.USDT!, process.env.NAD!);

console.log({ pair, isValidPair });
```

### 1.6 Quick verification checklist
- `pair` is not `0x0000000000000000000000000000000000000000`.
- `isValidPair == true`.
- Returned pair matches `PAIR_USDT_NAD` in `envs/deployed.local.env`.

<a id="cookbook"></a>
## 2. Cookbook (Scenario-based)
## 2.A Pair detail page (`getPairView`)
### Purpose
Load static metadata, dynamic accounting fields, and user state in one call.

### Inputs
- `pair`: target pair address.
- `user`: connected wallet address (or tracked address).

### Call sequence
1. Call `getPairView(pair, user)`.
2. Inspect `s.status`, `d.status`, `u.status`.
3. Render full UI on status `0`, render warning UI on status `2`.

### Success response pattern
- `s.status == 0`
- `d.status == 0`
- `u.status == 0` (or `2` depending on user/router conditions)

### Failure/degraded cases
- `s.status == 1` or `d.status == 1` or `u.status == 1`: invalid pair path.
- `d.status == 2`: token `balanceOf` read degraded in dynamic accounting.
- `u.status == 2`: zero user, or allowance read degraded.

### Recovery
- For status `1`: stop rendering pair detail actions; show invalid-pair state.
- For status `2`: render partial data with degraded badge and retry option.

## 2.B Pair list pagination (`getPairsLength` -> `getPairsPage` -> batch details)
### Purpose
Build pair list pages without external indexers when factory enumeration is available.

### Inputs
- `start`: zero-based offset.
- `count`: page size, must be `<= 200`.

### Call sequence
1. Call `getPairsLength()`.
2. If `ok=false`, switch to external indexing path.
3. Call `getPairsPage(start, count)`.
4. If `ok=true`, call `getPairsStatic(page)` and/or `getPairsDynamic(page)`.

### Success response pattern
- `getPairsLength()` returns `(true, N)`.
- `getPairsPage()` returns `(true, address[])`.

### Failure/degraded cases
- `getPairsLength()` returns `(false, 0)` when enumeration function is unavailable/fails.
- `getPairsPage()` returns `(false, [])` when `allPairs` index call fails.
- Revert with `COUNT_TOO_LARGE` when `count > 200`.
- Revert with `BATCH_TOO_LARGE` when array length for batch calls exceeds 200.

### Recovery
- Use page sizes 25/50/100; avoid requesting 200 by default.
- On `(false, ...)`, route to indexer-backed discovery.
- On revert for oversize requests, clamp request size and retry.

## 2.C User portfolio row (`getUserState`)
### Purpose
Show user token balances, LP balance, and allowance to router for a pair.

### Inputs
- `pair`
- `user`

### Call sequence
1. Call `getUserState(pair, user)`.
2. Read `token0Balance`, `token1Balance`, `lpBalance`.
3. Read allowance fields for action readiness.

### Success response pattern
- `status == 0`

### Failure/degraded cases
- `status == 1`: pair is invalid.
- `status == 2`: `user == address(0)` or allowance read degraded.

### Recovery
- Wallet disconnected: do not call with zero user from UI; gate earlier.
- Allowance degraded: disable write CTA and ask user to retry read.

## 2.D Incident handling playbook
### Situation 1: `ok=false` from `getPairsLength`/`getPairsPage`
- Meaning: factory enumeration path unavailable or failed.
- Action: use indexer path for discovery and keep Lens for per-pair reads.

### Situation 2: frequent `status=2` in dynamic/user reads
- Meaning: non-standard token behavior or temporary RPC inconsistency.
- Action: show partial UI, retry with backoff, log degraded frequency.

### Situation 3: reverts with `COUNT_TOO_LARGE` / `BATCH_TOO_LARGE`
- Meaning: caller exceeded hard batch limits.
- Action: clamp `count` and batch input length to `<= 200`.

<a id="api-reference"></a>
## 3. API Reference
### 3.1 Contract-level getters and constants
| Item | Type | Meaning |
|---|---|---|
| `factory()` | `address` | Factory address configured at deployment. |
| `router()` | `address` | Router address configured at deployment (can be zero). |
| `LP_FEE_BPS()` | `uint16` | Lens display constant: `20`. |
| `MAX_BATCH()` | `uint256` | Hard batch limit: `200`. |

### 3.2 Function-by-function reference
#### `getPair`
| Item | Details |
|---|---|
| Signature | `getPair(address tokenA, address tokenB) returns (address pair, bool isValidPair)` |
| Parameters | `tokenA`, `tokenB` |
| Returns | `pair`: mapped pair address or zero. `isValidPair`: factory `isPair` result when pair exists. |
| Success condition | Call returns normally. |
| Failure mode | Upstream factory call may revert (RPC or contract-level). |
| Example response | `(0xPair, true)` / `(0xPair, false)` / `(0x000..., false)` |

#### `getPairStatic`
| Item | Details |
|---|---|
| Signature | `getPairStatic(address pair) returns (PairStatic s)` |
| Parameters | `pair` |
| Returns | Full `PairStatic` struct. |
| Success condition | If `factory.isPair(pair)` true and downstream reads succeed, `s.status=0`. |
| Failure mode | If pair invalid, returns `s.status=1` without revert. Underlying pair/factory call can still revert. |
| Example response | `s.status=0`, with token metadata and tax fields populated. |

#### `getPairDynamic`
| Item | Details |
|---|---|
| Signature | `getPairDynamic(address pair) returns (PairDynamic d)` |
| Parameters | `pair` |
| Returns | Full `PairDynamic` struct. |
| Success condition | `d.status=0` when both token `balanceOf` reads succeed. |
| Failure mode | `d.status=1` for invalid pair. `d.status=2` when one or more balance reads fail. |
| Example response | `d.status=0`, reserve/raw/expected/dust/vault fields populated. |

#### `getUserState`
| Item | Details |
|---|---|
| Signature | `getUserState(address pair, address user) returns (UserState u)` |
| Parameters | `pair`, `user` |
| Returns | Full `UserState` struct. |
| Success condition | `u.status=0` when pair valid and allowance reads succeed (or router is zero). |
| Failure mode | `u.status=1` invalid pair. `u.status=2` zero user or allowance read failure. |
| Example response | `u.status=0`, balances/allowances populated. |

#### `getPairView`
| Item | Details |
|---|---|
| Signature | `getPairView(address pair, address user) returns (PairStatic s, PairDynamic d, UserState u)` |
| Parameters | `pair`, `user` |
| Returns | Combined static + dynamic + user state. |
| Success condition | Call returns tuple without revert. |
| Failure mode | Inherited from `getPairStatic/getPairDynamic/getUserState` behaviors. |
| Example response | `s.status=0`, `d.status=0`, `u.status=0`. |

#### `getPairsLength`
| Item | Details |
|---|---|
| Signature | `getPairsLength() returns (bool ok, uint256 len)` |
| Parameters | None |
| Returns | `ok`: whether factory enumeration call worked. `len`: pair count when `ok=true`. |
| Success condition | `(true, N)` |
| Failure mode | `(false, 0)` on unsupported or failed `allPairsLength` low-level call. |
| Example response | `(true, 123)` |

#### `getPairsPage`
| Item | Details |
|---|---|
| Signature | `getPairsPage(uint256 start, uint256 count) returns (bool ok, address[] pairs)` |
| Parameters | `start`, `count` (`count <= 200`) |
| Returns | `ok` + page array. |
| Success condition | `ok=true`; returns empty array when `start >= len`. |
| Failure mode | Revert `COUNT_TOO_LARGE` if `count > 200`. Returns `(false, [])` on failed low-level `allPairs` calls. |
| Example response | `(true, [0xPair1, 0xPair2])` |

#### `getPairsStatic`
| Item | Details |
|---|---|
| Signature | `getPairsStatic(address[] pairs) returns (PairStatic[] out)` |
| Parameters | `pairs` array, length `<= 200` |
| Returns | Array of `PairStatic`. |
| Success condition | Returns one output per input. |
| Failure mode | Revert `BATCH_TOO_LARGE` if length exceeds 200. |
| Example response | `[{status:0,...},{status:1,...}]` |

#### `getPairsDynamic`
| Item | Details |
|---|---|
| Signature | `getPairsDynamic(address[] pairs) returns (PairDynamic[] out)` |
| Parameters | `pairs` array, length `<= 200` |
| Returns | Array of `PairDynamic`. |
| Success condition | Returns one output per input. |
| Failure mode | Revert `BATCH_TOO_LARGE` if length exceeds 200. |
| Example response | `[{status:0,...},{status:2,...}]` |

### 3.3 Struct field dictionary
### `PairStatic`
| Field | Type | Meaning | Notes |
|---|---|---|---|
| `status` | `uint8` | 0 OK, 1 INVALID_PAIR, 2 DEGRADED | For this struct, 2 is not normally used. |
| `pair` | `address` | Queried pair | Echo of input. |
| `token0` | `address` | Pair token0 | Zero on invalid pair path. |
| `token1` | `address` | Pair token1 | Zero on invalid pair path. |
| `quoteToken` | `address` | Quote token configured by pair |  |
| `baseToken` | `address` | Non-quote token | Derived by `isQuote0`. |
| `isQuote0` | `bool` | Whether quote token equals token0 |  |
| `isQuoteSupported` | `bool` | Factory quote-token support flag |  |
| `buyTaxBps` | `uint16` | Buy tax in bps |  |
| `sellTaxBps` | `uint16` | Sell tax in bps |  |
| `taxCollector` | `address` | Tax collector address |  |
| `lpFeeBps` | `uint16` | Lens constant LP fee display | Always 20. |

### `PairDynamic`
| Field | Type | Meaning | Notes |
|---|---|---|---|
| `status` | `uint8` | 0 OK, 1 INVALID_PAIR, 2 DEGRADED | 2 when token raw balance reads fail. |
| `pair` | `address` | Queried pair | Echo of input. |
| `reserve0Eff` | `uint112` | Effective reserve0 | From pair `getReserves`. |
| `reserve1Eff` | `uint112` | Effective reserve1 | From pair `getReserves`. |
| `blockTimestampLast` | `uint32` | Last reserve timestamp | From pair `getReserves`. |
| `raw0` | `uint256` | Raw token0 balance in pair | Zero if read failed. |
| `raw1` | `uint256` | Raw token1 balance in pair | Zero if read failed. |
| `vaultQuote` | `uint96` | Accumulated quote tax vault | From pair. |
| `rawQuote` | `uint256` | Raw quote-side balance | Derived from raw0/raw1. |
| `rawBase` | `uint256` | Raw base-side balance | Derived from raw0/raw1. |
| `expectedQuoteRaw` | `uint256` | Expected quote raw = reserveQuote + vault |  |
| `expectedBaseRaw` | `uint256` | Expected base raw = reserveBase |  |
| `dustQuote` | `uint256` | Positive rawQuote surplus | 0 if no surplus. |
| `dustBase` | `uint256` | Positive rawBase surplus | 0 if no surplus. |
| `vaultDrift` | `bool` | `rawQuote < vaultQuote` | Indicates quote-vault inconsistency risk. |

### `UserState`
| Field | Type | Meaning | Notes |
|---|---|---|---|
| `status` | `uint8` | 0 OK, 1 INVALID_PAIR, 2 DEGRADED | 2 for zero-user or allowance degradation. |
| `pair` | `address` | Queried pair | Echo of input. |
| `user` | `address` | Queried user | Echo of input. |
| `token0` | `address` | Pair token0 | Zero if early return path. |
| `token1` | `address` | Pair token1 | Zero if early return path. |
| `token0Balance` | `uint256` | User token0 balance | Zero if token read failed. |
| `token1Balance` | `uint256` | User token1 balance | Zero if token read failed. |
| `lpBalance` | `uint256` | User LP balance | Zero if token read failed. |
| `token0AllowanceToRouter` | `uint256` | token0 allowance to router | 0 when router is zero or allowance read failed. |
| `token1AllowanceToRouter` | `uint256` | token1 allowance to router | 0 when router is zero or allowance read failed. |
| `lpAllowanceToRouter` | `uint256` | LP allowance to router | 0 when router is zero or allowance read failed. |

<a id="failure-model"></a>
## 4. Error/Failure Model
### 4.1 Explicit revert reasons
| Revert reason | Where | Trigger |
|---|---|---|
| `ZERO_FACTORY` | constructor | deploy with zero factory address |
| `COUNT_TOO_LARGE` | `getPairsPage` | `count > MAX_BATCH(200)` |
| `BATCH_TOO_LARGE` | `getPairsStatic`, `getPairsDynamic` | input length > 200 |

### 4.2 Function failure behavior matrix
| Function | Revert | Soft fail (`ok=false`) | Status fail (`status=1/2`) |
|---|---|---|---|
| `getPair` | possible upstream revert | no | returns bool (`isValidPair`) |
| `getPairStatic` | possible upstream revert | no | `status=1` for invalid pair |
| `getPairDynamic` | possible upstream revert | no | `status=1` invalid pair, `status=2` degraded reads |
| `getUserState` | possible upstream revert | no | `status=1` invalid pair, `status=2` zero user or degraded allowance |
| `getPairView` | inherited | no | inherited from each component struct |
| `getPairsLength` | no (guarded low-level call) | yes | no |
| `getPairsPage` | `COUNT_TOO_LARGE` only | yes | no |
| `getPairsStatic` | `BATCH_TOO_LARGE` | no | each element may have `status=1` |
| `getPairsDynamic` | `BATCH_TOO_LARGE` | no | each element may have `status=1/2` |

### 4.3 Client handling rules
- Revert: treat as request error; clamp input or fix config before retry.
- `ok=false`: treat as capability/runtime failure; switch to fallback path.
- `status=1`: treat as invalid business object; stop that branch.
- `status=2`: treat as partial-data mode; render with warning and retry affordance.

## 5. Pagination & Throughput
### 5.1 Pagination rules
- Pagination is offset-based (`start`, `count`), not cursor-based.
- `count` must be `<= 200`.
- `start >= len` returns `(true, [])`.

### 5.2 Throughput and rate limits
- Lens contract has no built-in rate limiting.
- Effective limits come from your RPC provider.
- Keep reads batched and bounded to avoid provider-side throttling.

### 5.3 Recommended page sizes
- Stable infra: `count=100`
- General default: `count=50`
- Unstable/public RPC: `count=25`

### 5.4 Retry/backoff policy (recommended)
- Retry only on transport/provider failures and temporary RPC errors.
- Do not blind-retry deterministic reverts (`COUNT_TOO_LARGE`, `BATCH_TOO_LARGE`).
- Backoff baseline: `300ms`, `600ms`, `1200ms`, with jitter ±20%.
- Max retry attempts: 3 for UI, 5 for backend jobs.

## 6. Versioning & Compatibility
### 6.1 Version labels
- Contract: NadSwap Lens V1.1
- This document: Lens Guide V1.1

### 6.2 Compatibility policy
- Additive fields/functions: minor documentation update.
- Behavioral change affecting existing integration logic: major version guidance update.
- Any ABI-breaking change should be treated as major contract version change.

### 6.3 Documentation sync policy
- Keep KR/EN section numbering and table structure aligned.
- Keep Deployment guide links pointing to this guide's anchors.

<a id="appendix"></a>
## 7. Appendix (cast/TS examples)
### 7.1 `cast call` examples
```bash
# Core getters
cast call "$LENS_ADDRESS" "factory()(address)" --rpc-url "$RPC_URL"
cast call "$LENS_ADDRESS" "router()(address)" --rpc-url "$RPC_URL"
cast call "$LENS_ADDRESS" "LP_FEE_BPS()(uint16)" --rpc-url "$RPC_URL"
cast call "$LENS_ADDRESS" "MAX_BATCH()(uint256)" --rpc-url "$RPC_URL"

# Pair-level reads
cast call "$LENS_ADDRESS" "getPair(address,address)(address,bool)" "$TOKEN_A" "$TOKEN_B" --rpc-url "$RPC_URL"
cast call "$LENS_ADDRESS" "getPairStatic(address)((uint8,address,address,address,address,address,bool,bool,uint16,uint16,address,uint16))" "$PAIR" --rpc-url "$RPC_URL"
cast call "$LENS_ADDRESS" "getPairDynamic(address)((uint8,address,uint112,uint112,uint32,uint256,uint256,uint96,uint256,uint256,uint256,uint256,uint256,uint256,bool))" "$PAIR" --rpc-url "$RPC_URL"
cast call "$LENS_ADDRESS" "getUserState(address,address)((uint8,address,address,address,address,uint256,uint256,uint256,uint256,uint256,uint256))" "$PAIR" "$USER" --rpc-url "$RPC_URL"
cast call "$LENS_ADDRESS" "getPairView(address,address)" "$PAIR" "$USER" --rpc-url "$RPC_URL"

# List reads
cast call "$LENS_ADDRESS" "getPairsLength()(bool,uint256)" --rpc-url "$RPC_URL"
cast call "$LENS_ADDRESS" "getPairsPage(uint256,uint256)(bool,address[])" 0 50 --rpc-url "$RPC_URL"
cast call "$LENS_ADDRESS" "getPairsStatic(address[])" "[$PAIR]" --rpc-url "$RPC_URL"
cast call "$LENS_ADDRESS" "getPairsDynamic(address[])" "[$PAIR]" --rpc-url "$RPC_URL"
```

### 7.2 TypeScript helper sketch (ethers)
```ts
import { Contract, JsonRpcProvider } from "ethers";

const lensAbi = [
  "function getPair(address,address) view returns (address,bool)",
  "function getPairView(address,address) view returns ((uint8,address,address,address,address,address,bool,bool,uint16,uint16,address,uint16),(uint8,address,uint112,uint112,uint32,uint256,uint256,uint96,uint256,uint256,uint256,uint256,uint256,uint256,bool),(uint8,address,address,address,address,uint256,uint256,uint256,uint256,uint256,uint256))",
  "function getPairsLength() view returns (bool,uint256)",
  "function getPairsPage(uint256,uint256) view returns (bool,address[])"
] as const;

const provider = new JsonRpcProvider(process.env.RPC_URL!);
const lens = new Contract(process.env.LENS_ADDRESS!, lensAbi, provider);

export async function loadPairView(pair: string, user: string) {
  const [s, d, u] = await lens.getPairView(pair, user);
  return {
    staticStatus: Number(s[0]),
    dynamicStatus: Number(d[0]),
    userStatus: Number(u[0]),
    pair,
    user,
    raw: { s, d, u }
  };
}
```
