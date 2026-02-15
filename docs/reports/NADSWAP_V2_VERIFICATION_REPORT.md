# NadSwap V2 Verification Report

Date: 2026-02-14

## Scope
- Core: `UniswapV2Pair`, `UniswapV2Factory`
- Periphery: `UniswapV2Library`, `UniswapV2Router02`
- Foundry suites: non-fork strict set + `test/fork/**`
- Gates: storage layout, traceability, math consistency, migration signoff

## Executed Commands
- `cd protocol && FOUNDRY_OFFLINE=true forge test --no-match-path "test/fork/**"`
- `scripts/runners/run_fork_tests.sh`
- `cd protocol && MONAD_FORK_ENABLED=1 MONAD_RPC_URL=<rpc> forge test`
- `python3 scripts/gates/check_storage_layout.py`
- `python3 scripts/gates/check_traceability.py`
- `python3 scripts/gates/check_math_consistency.py`
- `python3 scripts/gates/check_migration_signoff.py`
- `python3 scripts/reports/collect_verification_metrics.py`
- `python3 scripts/reports/render_verification_reports.py`

## Results
<!-- GENERATED:START -->
- Metrics source: `docs/reports/NADSWAP_V2_VERIFICATION_METRICS.json`
- Generated at: `2026-02-15T15:17:36.036393+00:00`
- Git SHA: `87124cc101124dc53dd1872900109d2f7e8fedfa`
- Baseline source: `docs/reports/NADSWAP_V2_VERIFICATION_BASELINE.json`
- Foundry tests (non-fork strict): **PASS** (`112/112`)
- Foundry tests (fork suites): **PASS** (`47/47`)
- Foundry tests (non-fork all): **PASS** (`117/117`)
- Traceability requirements: **PASS** (`30/30`)
- Spec Section 16 named tests: **PASS** (`90/90`)
- Spec Section 16 named invariants: **PASS** (`5/5`)
- Math consistency vectors: **PASS** (`1386/1386`)
- Migration checklist items: **PASS** (`13/13`)
<!-- GENERATED:END -->

## Recent Verification Additions
- Initialize auth coverage strengthened:
  - `test_initialize_nonFactory_revert`
- FOT hard-revert coverage expanded to all router supporting entrypoints:
  - `test_router_supportingFOT_notSupported_exactETHForTokens`
  - `test_router_supportingFOT_notSupported_exactTokensForETH`
  - `test_router_supportingFOT_notSupported_removeLiquidityETH`
  - `test_router_supportingFOT_notSupported_removeLiquidityETHWithPermit`
- Event/accounting assertions strengthened:
  - `test_swapEvent_usesEffIn` now validates emitted `Swap` inputs directly
  - `test_claim_vaultReset_reserveSync` now asserts claim keeps reserves unchanged
  - `test_claim_doesNotAbsorbDust` verifies quote dust remains skimmable after claim
- Regression scope expanded at `tax=0`:
  - router quote/execution parity (buy + sell)
  - feeTo-off mint/burn parity
- Invariants expanded:
  - `totalSupply > 0 => reserve0 > 0 && reserve1 > 0`
  - factory pair mapping consistency (`isPair` and `getPair` both directions)
- Informational hardening promoted to explicit implementation:
  - Pair K-check now includes explicit multiply-overflow guard (`K_MULTIPLY_OVERFLOW`)
  - Added regression coverage: `test_kMultiplyOverflow_revert`

## Traceability/Docs Alignment Updates
- `PAIR-001` mapping updated to initialize-focused tests
- `ROUT-002` mapping updated to all FOT supporting entrypoints
- Spec wording aligned with implementation for `sellTax=10000` boundary revert:
  - `TAX_TOO_HIGH` (max-tax guard precedence)

## Status
- Section 16 named coverage is sourced from the GENERATED block above.
- All strict CI-equivalent verification gates are green on the current tree.
- Fork verification is now explicit-only (no silent pass path without fork env).
