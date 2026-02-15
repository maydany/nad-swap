# NadSwap Frontend (`apps/nadswap`)

Vite + React + Tailwind frontend for the NadSwap main dApp.

## Prerequisites

권장 루트 워크플로우:
```bash
pnpm setup
pnpm local:up
```

`pnpm local:up`은 배포/검증/env sync 후 프론트를 실행합니다.

수동 실행이 필요하면:
```bash
pnpm deploy:local
pnpm env:sync:nadswap
pnpm dev:nadswap
```

## Run

```bash
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
