# NadSwap Lens V1.1 Deployment Guide

## Related Docs
- KR Guide (full): [NADSWAP_LENS_V1_1_GUIDE_KR.md](./NADSWAP_LENS_V1_1_GUIDE_KR.md)
- KR Quickstart: [KR Quickstart](./NADSWAP_LENS_V1_1_GUIDE_KR.md#quickstart)
- KR API Reference: [KR API Reference](./NADSWAP_LENS_V1_1_GUIDE_KR.md#api-reference)
- KR Failure Model: [KR Failure Model](./NADSWAP_LENS_V1_1_GUIDE_KR.md#failure-model)
- EN Guide (full): [NADSWAP_LENS_V1_1_GUIDE_EN.md](./NADSWAP_LENS_V1_1_GUIDE_EN.md)
- EN Quickstart: [EN Quickstart](./NADSWAP_LENS_V1_1_GUIDE_EN.md#quickstart)
- EN API Reference: [EN API Reference](./NADSWAP_LENS_V1_1_GUIDE_EN.md#api-reference)
- EN Failure Model: [EN Failure Model](./NADSWAP_LENS_V1_1_GUIDE_EN.md#failure-model)
- Lens Docs Index: [README.md](./README.md)

## Scope
- Target contract: `lens/src/NadSwapLensV1_1.sol`
- Compiler: `solc 0.8.25`
- EVM target: `cancun`
- Standalone output env file: `envs/deployed.lens.env`

## Prerequisites
1. `forge` installed.
2. `LENS_FACTORY` must point to a deployed NadSwap V2 factory.
3. `LENS_ROUTER` is optional. If unset, router is stored as `address(0)`.

## Build and Tests
```bash
cd lens
forge build
FOUNDRY_OFFLINE=true forge test --no-match-path "test/fork/**" -vv
forge test --match-path "test/fork/**" --fork-url "$MONAD_RPC_URL" --fork-block-number "$MONAD_FORK_BLOCK" -vv
```

Or run the integrated suite from repo root:
```bash
./scripts/runners/run_lens_tests.sh
```

Runner options:

| Option | Meaning |
|--------|---------|
| `--skip-fork` | Run Lens unit tests only |
| `--rpc <url>` | Override `MONAD_RPC_URL` |
| `--chain-id <id>` | Override `MONAD_CHAIN_ID` |
| `--block <n>` | Override `MONAD_FORK_BLOCK` |
| `--latest` | Set `MONAD_FORK_BLOCK=0` (latest block) |
| `-v|-vv|-vvv|-vvvv` | Forge verbosity |

## Deploy
Set required environment variables:
```bash
export LENS_FACTORY=0xYourFactoryAddress
# Optional
export LENS_ROUTER=0xYourRouterAddress
```

Run deployment script:
```bash
cd lens
forge script script/DeployLens.s.sol:DeployLensScript \
  --rpc-url "$MONAD_RPC_URL" \
  --broadcast
```

## Local Integrated Deploy (Anvil)
For local development, run the root deploy script to deploy both core and lens in one flow:
```bash
./scripts/deploy_local.sh
```

What this integrated flow does:
- Deploys core contracts (`WETH`, `USDT`, `NAD`, `Factory`, `Router`, `Pair`) on Anvil.
- Deploys `NadSwapLensV1_1` using the deployed local `FACTORY`/`ROUTER`.
- Runs read-path smoke validation against the deployed Lens instance:
  - `factory()`
  - `router()`
  - `getPair(USDT,NAD)`
  - `getPairsLength()`
  - `getPairsPage(0,1)`
  - `getPairView(pair,deployer)`
- Writes integrated output to:
  - `envs/deployed.local.env` (core + lens merged output)
  - `envs/deployed.lens.env` is temporary and removed at the end of `scripts/deploy_local.sh`

## Deployment Outputs by Mode

### Standalone Lens deploy (`forge script ...DeployLensScript`)
- Output: `envs/deployed.lens.env`
- Expected keys:
```bash
export LENS_ADDRESS=0x...
export LENS_FACTORY=0x...
export LENS_ROUTER=0x...
export LENS_CHAIN_ID=...
```

### Integrated local deploy (`./scripts/deploy_local.sh`)
- Output: `envs/deployed.local.env` (single source of truth)
- Includes core + lens keys:
```bash
WETH=0x...
USDT=0x...
NAD=0x...
FACTORY=0x...
ROUTER=0x...
PAIR_USDT_NAD=0x...
LENS_ADDRESS=0x...
LENS_FACTORY=0x...
LENS_ROUTER=0x...
LENS_CHAIN_ID=31337
```

## Quick Read Validation
```bash
cast call "$LENS_ADDRESS" "getPairsLength()(bool,uint256)" --rpc-url "$RPC_URL"
cast call "$LENS_ADDRESS" "getPair(address,address)(address,bool)" "$TOKEN_A" "$TOKEN_B" --rpc-url "$RPC_URL"
```

For full response schema and failure semantics, see:
- [KR API Reference](./NADSWAP_LENS_V1_1_GUIDE_KR.md#api-reference)
- [EN API Reference](./NADSWAP_LENS_V1_1_GUIDE_EN.md#api-reference)
