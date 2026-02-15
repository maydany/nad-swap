# NadSwap Frontend (`apps/nadswap`)

Vite + React + Tailwind frontend for the NadSwap main dApp.

## Prerequisites

1. Deploy local contracts and Lens:
   ```bash
   ./deploy_local.sh
   ```
2. Sync frontend env from deployment output:
   ```bash
   pnpm env:sync:nadswap
   ```

## Run

```bash
pnpm install
pnpm dev:nadswap
```

The app expects the generated env file at `apps/nadswap/.env.local`.

## Build / Test

```bash
pnpm lint:nadswap
pnpm test:nadswap
pnpm build:nadswap
```

## What is included in MVP

- Wallet connect/disconnect
- Three-step trade action flow: `Switch Network -> Approve -> Swap`
- Router quote + `amountOutMin` (0.5% slippage)
- Lens `getPairView` status panel
  - `status=0`: normal
  - `status=1`: invalid pair, trade blocked
  - `status=2`: degraded mode, trade blocked + refetch
