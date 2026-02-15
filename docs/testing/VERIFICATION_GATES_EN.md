# NadSwap V2 — Verification Gates Reference

> Detailed guide to every gate executed by `run_all_tests.sh`.

---

## Overview

`run_all_tests.sh` executes **16 automated verification gates** across 6 layers: compilation, security, storage compatibility, mathematical correctness, specification traceability, documentation consistency, and live-chain fork testing.

```
run_all_tests.sh
├── run_local_gates.sh (Strict Gate)
│   ├── 1.  Build
│   ├── 2.  Slither Static Analysis
│   ├── 3.  Storage Layout
│   ├── 4.  P0 Smoke (swap/tax guard paths)
│   ├── 5.  Lightweight Invariant
│   ├── 6.  Unit / Fuzz / Regression
│   ├── 7.  Nightly High-Depth Invariant
│   ├── 8.  Nightly Large-Domain K/Overflow Fuzz
│   ├── 9.  Math Consistency (Python)
│   ├── 10. Traceability
│   ├── 11. Migration Checklist
│   ├── 12. Fork Test Suite
│   ├── 13. Collect Verification Metrics
│   ├── 14. Render Verification Reports
│   ├── 15. Docs Symbol Refs
│   └── 16. Docs Consistency
└── run_fork_tests.sh (Monad Fork Suite — re-run)
```

If **any** single gate fails, the entire run reports `FAIL`. Total: **16 gates**.

---

## Gate Details

### 1. Build

| Item | Value |
|------|-------|
| Command | `forge build` |
| Checks | Solidity source compiles without errors |

Catches type mismatches, missing imports, interface implementation gaps, and Solidity version conflicts. This is the prerequisite for all subsequent gates.

---

### 2. Slither Static Analysis

| Item | Value |
|------|-------|
| Script | `scripts/gates/check_slither_gate.py` |
| Tool | [Slither](https://github.com/crytic/slither) by Trail of Bits |
| Fail level | `medium` (configurable via `SLITHER_FAIL_LEVEL`) |
| Scope | `protocol/src/` only (test, lib, upstream excluded) |

Runs Slither against all production contracts and fails if any finding at or above the configured severity is detected.

**What it catches:**
- Reentrancy vulnerabilities
- Unchecked external calls
- Missing access controls
- Unused state variables
- Dangerous arithmetic patterns

---

### 3. Storage Layout

| Item | Value |
|------|-------|
| Script | `scripts/gates/check_storage_layout.py` |
| Baseline | Upstream Uniswap V2 Pair at pinned commit `ee547b17...` |

Compares the storage layout of the upstream `UniswapV2Pair` against the current `NadSwapV2Pair` using `forge inspect <contract> ... storageLayout`.

**Two invariants enforced:**

1. **V2 fields preserved** — `reserve0`, `reserve1`, `blockTimestampLast`, `price0CumulativeLast`, `price1CumulativeLast`, `kLast`, `unlocked` must occupy the exact same slot, offset, and type as upstream.
2. **NadSwap fields are append-only** — `quoteToken`, `buyTaxBps`, `sellTaxBps`, `initialized`, `taxCollector`, `accumulatedQuoteTax` must be placed in slots strictly after the last V2 field.

Also verifies that the upstream Git HEAD matches the pinned commit SHA and provenance file.

**Why it matters:** Inserting a field between V2 slots would shift all subsequent storage, corrupting live data if the contract were ever upgraded or if external tooling relies on known slot positions.

---

### 4. P0 Smoke Gate (swap/tax guard paths)

| Item | Value |
|------|-------|
| Commands | `forge test --match-path "test/core/PairSwapGuards.t.sol"` then `forge test --match-path "test/core/PairFlashQuote.t.sol"` |
| Priority | P0 — runs before any other test gate |

Runs the highest-priority swap guard and flash-quote test files **first**, before the broader test suites. This provides fast-fail feedback on the most critical tax-trigger and guard-path logic.

**Key truth-table regression tests included:**
- `test_trigger_buyTax_only_when_quoteIn_and_baseOut` — verifies that buy tax accrues **only** when the swap direction is Quote → Base (quote-in, base-out). Ensures no tax is triggered on any other direction.
- `test_trigger_sellTax_only_when_quoteOut` — verifies that sell tax accrues **only** when quote tokens flow out. Uses flash-style repayment to isolate the sell direction.

These two tests form a **truth-table regression** covering all four possible (direction × tax-type) matrix entries, ensuring the tax trigger conditions are never accidentally inverted or broadened.

---

### 5 & 7. Invariant Tests

| Item | Gate 5 (Lightweight) | Gate 7 (Nightly) |
|------|---------------------|-------------------|
| Profile | default | `invariant-nightly` |
| Depth | standard | high |
| Purpose | Fast smoke-test | Deep exploration |

Foundry's invariant testing calls contract functions in **random order with random parameters**, then checks that invariants hold after every call.

**Invariants tested (examples):**
- K(effective) ≥ K_old after every swap
- vault ≤ raw quote balance at all times
- reserves == effective balances
- LP total supply consistent with pool state

This catches bugs that only surface under unexpected call sequences (e.g., mint → swap → burn → swap → claim in rapid succession).

---

### 6. Unit / Fuzz / Regression Tests

| Item | Value |
|------|-------|
| Command | `forge test --no-match-path "test/{fork,invariant}/**"` |
| Count | ~107 tests (strict) |

All non-fork, non-invariant tests grouped by concern:

| File | Coverage |
|------|----------|
| `Factory.t.sol` | Pair creation, duplicate prevention, access control |
| `FactoryAdminExt.t.sol` | Tax config updates, quote token management |
| `PairLifecycle.t.sol` | Full mint → swap → burn lifecycle |
| `PairSwap.t.sol` | Buy/sell swaps, tax accrual, vault accumulation |
| `PairSwapGuards.t.sol` | Guard conditions, P0 truth-table tax triggers, vault overflow, K overflow |
| `PairFlashQuote.t.sol` | Flash swap edge cases |
| `ClaimTaxAdvanced.t.sol` | Tax claim, reentrancy defense, vault reset |
| `Regression.t.sol` | Previously discovered bugs do not resurface |
| `PairKOverflowDomain.t.sol` | Large-domain fuzz: K-invariant and K_MULTIPLY_OVERFLOW at 2¹⁰⁸–2¹¹¹ reserves |
| `FuzzInvariant.t.sol` | Fuzz-based mathematical property verification |
| `RouterLibrary.t.sol` | Library calculation accuracy |
| `RouterQuoteParity.t.sol` | Router quote vs. actual execution match |
| `PolicyEnforcement.t.sol` | Router policy enforcement (quote token validation, etc.) |

Fuzz tests generate random inputs (including edge values like 0, 1, max uint) across 64–256 runs per test.

---

### 8. Nightly Large-Domain K/Overflow Fuzz

| Item | Value |
|------|-------|
| File | `protocol/test/core/PairKOverflowDomain.t.sol` |
| Profile | `invariant-nightly` |
| Fuzz runs | 1,024 per test |
| Reserve range | 2¹⁰⁸ – 2¹¹¹ (symmetric) |

Dedicated fuzz gate that stress-tests K-invariant and overflow guards in the **large-reserve domain** (reserves set to 2¹⁰⁸ through 2¹¹¹, far beyond typical 18-decimal token pools).

**Tests:**

| Test | Purpose |
|------|---------|
| `testFuzz_largeDomain_buy_kInvariant_holds` | K never decreases after a buy swap with large reserves. Uses bucketed input amounts (low/mid/high/ultra-large). |
| `testFuzz_largeDomain_sell_kInvariant_holds` | K never decreases after a sell swap with large reserves. Sell capped at 1% of reserve to stay within liquidity bounds. |
| `testFuzz_largeAmount_sell_revertsWithKMultiplyOverflow` | Huge base-in amounts (2²²⁰–2²⁴⁰) correctly revert with `K_MULTIPLY_OVERFLOW` instead of silently wrapping. |

Running at 1,024 fuzz iterations provides high statistical confidence that the K-check and overflow guard hold across the entire uint112 domain.

---

### 9. Math Consistency (Python Cross-Verification)

| Item | Value |
|------|-------|
| Script | `scripts/gates/check_math_consistency.py` (677 lines) |
| Vectors | ~1,386 test vectors |
| Language | Python (arbitrary-precision integers) |

The most rigorous gate. It **re-implements the Pair swap logic entirely in Python** and verifies that Library quotes and Pair execution agree mathematically.

**4 directions verified:**

| # | Direction | Method | Assertion |
|---|-----------|--------|-----------|
| 1 | Buy exact-in (Quote→Base) | `getAmountsOut` → Pair sim | Tax matches, K passes |
| 2 | Sell exact-in (Base→Quote) | `getAmountsOut` → Pair sim | gross/net diff ≤ 1 wei |
| 3 | Sell exact-out (Base→Quote) | `getAmountsIn` → Pair sim | gross exact match |
| 4 | Buy exact-out (Quote→Base) | `getAmountsIn` → Pair sim | effIn ≥ lib (LP-favorable) |

**Test vector matrix:**
- Reserves: 6 configurations (extreme imbalance, large-scale, small pool, etc.)
- Tax rates: 7 combinations (0/0 through 2000/2000)
- Quote side: 2 (token0=Quote / token1=Quote)
- Amount fractions: 5 (0.1% to 30% of reserve)

**Additional sub-tests:**
- **Boundary**: Exact threshold where buy tax flips from 0 → 1 wei
- **Sell roundtrip**: `floor → ceil` conversion error ≤ 1 wei
- **K-invariant stress**: Dust inputs (1 wei) against 10¹⁸ reserves, 20 sequential swaps
- **uint96 vault overflow**: Mathematical proof of practical impossibility
- **Multi-hop error accumulation**: 3-hop path error bounded by N wei

---

### 10. Traceability

| Item | Value |
|------|-------|
| Script | `scripts/gates/check_traceability.py` |
| Tracked IDs | Including FUZ-002, FUZ-003, REG-002, SEC-004, SEC-005 (recently added) |
| Inputs | `NADSWAP_V2_REQUIREMENTS.yaml`, `NADSWAP_V2_TRACE_MATRIX.md`, `NADSWAP_V2_IMPL_SPEC_EN.md` |

Ensures every requirement is implemented, tested, and documented. Specifically:

1. Every requirement ID in `REQUIREMENTS.yaml` has a row in the trace matrix
2. Every matrix row references a real code path (file exists on disk)
3. Every test function referenced in the matrix exists in `protocol/test/`
4. Every matrix row has a verification command
5. Every `test_*` / `invariant_*` name in Spec Section 16 exists in Solidity test files
6. Every spec-named test is mapped in the matrix coverage table
7. No extra rows exist in the matrix that are absent from the spec

---

### 11. Migration Checklist

| Item | Value |
|------|-------|
| Script | `scripts/gates/check_migration_signoff.py` |
| Input | `NADSWAP_V2_MIGRATION_SIGNOFF.md` |

Verifies that all **13 migration checklist items** (numbered 1–13) are present. These items represent the complete set of changes made during the Uniswap V2 → NadSwap V2 fork (fee rate change, tax mechanism, quote token concept, access control changes, etc.).

---

### 12. Fork Test Suite (Monad)

| Item | Value |
|------|-------|
| Script | `scripts/runners/run_fork_tests.sh` |
| Chain | Monad testnet (RPC fork) |
| Total tests | 47 |

Deploys contracts on a **fork of the live Monad testnet** and runs all fork-specific tests:

| Suite | Path | Tests |
|-------|------|-------|
| Core | `test/fork/core/` | 33 (lifecycle, swap, claim, factory policy) |
| Periphery | `test/fork/periphery/` | 11 (router parity, policy guards) |
| Fuzz Lite | `ForkFuzzLiteTest` | 3 (64 runs each) |

Unlike local Anvil tests, fork tests validate behavior on Monad's actual EVM implementation (which features parallel execution and other differences).

---

## Post-Gate Steps

### 13. Collect Verification Metrics

| Item | Value |
|------|-------|
| Script | `scripts/reports/collect_verification_metrics.py` |
| Output | `docs/reports/NADSWAP_V2_VERIFICATION_METRICS.json` |

Parses all gate results into a single JSON metrics file:

| Metric Key | Source | Example |
|------------|--------|---------|
| `non_fork_all` | forge test output | 112 |
| `non_fork_strict` | forge test (excl. fork + invariant) | 107 |
| `fork_suite_total` | fork-logs parsing | 47 |
| `requirements_count` | YAML requirement IDs | 30 |
| `spec_test_count` | Spec `test_*` names | 90 |
| `spec_invariant_count` | Spec `invariant_*` names | 5 |
| `math_consistency_total` | Python verification vectors | 1386 |
| `migration_items_total` | Migration checklist rows | 13 |

If a gate could not run due to environment issues, the collector falls back to baseline values (recorded as `BASELINE` status).

---

### 14. Render Verification Reports

| Item | Value |
|------|-------|
| Script | `scripts/reports/render_verification_reports.py` |
| Targets | `NADSWAP_V2_SPEC_CONFORMANCE_REPORT.md`, `NADSWAP_V2_VERIFICATION_REPORT.md` |

Injects the collected metrics into `<!-- GENERATED:START -->` / `<!-- GENERATED:END -->` blocks in the report files. In `--check` mode (used during gate runs), it fails if the rendered output differs from the file on disk — catching stale reports.

---

### 15. Docs Symbol Refs

| Item | Value |
|------|-------|
| Script | `scripts/gates/check_docs_symbol_refs.py` |
| Scope | All `.md` files in `docs/` |

Scans documentation for `forge inspect <target> ... storageLayout` commands and verifies that:
- The referenced contract name exists in `protocol/src/`
- The referenced `.sol` file path exists on disk

Catches documentation drift after contract renames or file moves.

---

### 16. Docs Consistency

| Item | Value |
|------|-------|
| Script | `scripts/gates/check_docs_consistency.py` |

The strictest documentation gate. Performs multiple cross-checks:

| Check | Description |
|-------|-------------|
| **Metrics drift** | JSON metric values must match live-counted source values |
| **Claim semantics** | Spec must contain correct claim behavior descriptions; outdated wording is forbidden |
| **Tax terminology** | Deprecated terms (`collector` standalone, `claimed quote fees`, `ClaimFeesAdvanced`) must not appear |
| **Fork doc modes** | Fork testing doc must describe both Mode A (Runner) and Mode B (Direct) |
| **Generated blocks sync** | Report GENERATED blocks must be up to date with latest metrics |

---

## Error Coverage Matrix

| Error Type | Catching Gate(s) |
|------------|------------------|
| Compilation failure | Build |
| Reentrancy / security vulnerability | Slither |
| Storage slot corruption | Storage Layout |
| Tax trigger direction inversion | P0 Smoke (truth-table regression) |
| Swap math off by ≥ 1 wei | Math Consistency |
| K-invariant violation at large reserves (2¹⁰⁸–2¹¹¹) | Large-Domain K/Overflow Fuzz |
| K_MULTIPLY_OVERFLOW silent wrapping | Large-Domain K/Overflow Fuzz |
| Existing test regression | Unit / Fuzz / Regression |
| Unexpected call-sequence invariant violation | Invariant (both) |
| Requirement without test coverage | Traceability |
| Missing migration checklist item | Migration |
| Monad-specific incompatibility | Fork Tests |
| Stale contract name in docs | Docs Symbol Refs |
| Doc content inconsistent with code | Docs Consistency |
