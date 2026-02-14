# NadSwap V2 Spec Conformance Report (Updated)

Date: 2026-02-14
Scope: `draft_1` excluded

## Validation Scope
- Included: `protocol/src`, `protocol/test`, `scripts`, `docs/traceability`, `docs/reports`
- Excluded: `draft_1/**`

## Evidence Commands
- `cd protocol && FOUNDRY_OFFLINE=true forge test --no-match-path "test/fork/**"`
- `scripts/runners/run_fork_tests.sh`
- `cd protocol && MONAD_FORK_ENABLED=1 MONAD_RPC_URL=<rpc> forge test`
- `python3 scripts/gates/check_storage_layout.py`
- `python3 scripts/gates/check_traceability.py`
- `python3 scripts/gates/check_math_consistency.py`
- `python3 scripts/gates/check_migration_signoff.py`
- `python3 scripts/reports/collect_verification_metrics.py`
- `python3 scripts/reports/render_verification_reports.py`

## Gate Results
<!-- GENERATED:START -->
- Metrics source: `docs/reports/NADSWAP_V2_VERIFICATION_METRICS.json`
- Generated at: `2026-02-14T19:02:31.425370+00:00`
- Git SHA: `e82348bdd51d4c1e90de0f070223e44c13eb4a8f`
- Baseline source: `docs/reports/NADSWAP_V2_VERIFICATION_BASELINE.json`
- Foundry tests (non-fork strict): **PASS** (`104/104`)
- Foundry tests (fork suites): **PASS** (`47/47`)
- Foundry tests (non-fork all): **PASS** (`109/109`)
- Traceability requirements: **PASS** (`30/30`)
- Spec Section 16 named tests: **PASS** (`87/87`)
- Spec Section 16 named invariants: **PASS** (`5/5`)
- Math consistency vectors: **PASS** (`1386/1386`)
- Migration checklist items: **PASS** (`13/13`)
<!-- GENERATED:END -->

## Section 16 Coverage Status
- Section 16 coverage values are sourced from the GENERATED block above.

## Conformance Judgment
- Sections 4~19 implementation/test conformance: **PASS (No missing named test IDs)**
- Informational item #35 hardening has been explicitly implemented in core swap path (`K_MULTIPLY_OVERFLOW`) with dedicated regression test coverage.
- Residual scope note: fork suites require explicit environment (`MONAD_FORK_ENABLED=1`, valid `MONAD_RPC_URL`) and no longer allow no-op passes.
