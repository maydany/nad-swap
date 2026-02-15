# NadSwap V2 — 검증 게이트 레퍼런스

> `run_all_tests.sh`가 실행하는 모든 게이트에 대한 상세 가이드.

---

## 개요

`run_all_tests.sh`는 아래 오케스트레이션으로 실행됩니다:

```
run_all_tests.sh
├── run_local_gates.sh --skip-fork
│   ├── 1.  Build (컴파일)
│   ├── 2.  Slither 정적 보안 분석
│   ├── 3.  Storage Layout (스토리지 레이아웃)
│   ├── 4.  P0 Smoke (swap/tax guard 경로)
│   ├── 5.  Lightweight Invariant (경량 불변조건)
│   ├── 6.  Unit / Fuzz / Regression (유닛·퍼즈·회귀)
│   ├── 7.  Nightly High-Depth Invariant (심층 불변조건)
│   ├── 8.  Nightly Large-Domain K/Overflow Fuzz (대형 도메인 K/오버플로 퍼즈)
│   ├── 9.  Math Consistency (수학적 일관성 — Python)
│   ├── 10. Traceability (추적성)
│   ├── 11. Migration Checklist (마이그레이션 체크리스트)
│   ├── 12. Fork Test Suite (포크 테스트)
│   ├── 13. Collect Verification Metrics (메트릭 수집)
│   ├── 14. Render Verification Reports (리포트 렌더링)
│   ├── 15. Docs Symbol Refs (문서 심볼 참조)
│   └── 16. Docs Consistency (문서 일관성)
├── run_lens_tests.sh                   (Lens unit + Monad fork smoke)
└── run_fork_tests.sh                   (Protocol Monad 포크 스위트)
```

`run_local_gates.sh`의 번호 1~16은 **local-gates 내부 게이트 개수**를 의미합니다.
`run_all_tests.sh`는 local-gates 실행 시 `--skip-fork`를 전달하고, fork suite를 별도 단계에서 실행합니다.

**하나라도** 실패하면 전체 결과가 `FAIL`로 보고됩니다.

## CLI 옵션 요약

### `run_all_tests.sh`

| 옵션 | 의미 |
|------|------|
| `--only lens` | Lens suite만 실행 |
| `--skip-lens` | Lens suite 실행 생략 |
| `--skip-fork` | Protocol fork + Lens fork smoke 실행 생략 |

### `scripts/runners/run_lens_tests.sh`

| 옵션 | 의미 |
|------|------|
| `--skip-fork` | Lens unit만 실행 |
| `--rpc <url>` | `MONAD_RPC_URL` override |
| `--chain-id <id>` | `MONAD_CHAIN_ID` override |
| `--block <n>` | `MONAD_FORK_BLOCK` override |
| `--latest` | `MONAD_FORK_BLOCK=0`으로 latest 블록 사용 |
| `-v|-vv|-vvv|-vvvv` | Forge verbosity |

---

## 게이트 상세

### 1. Build (컴파일)

| 항목 | 값 |
|------|---|
| 명령어 | `forge build` |
| 확인 사항 | Solidity 소스가 오류 없이 컴파일되는지 |

타입 불일치, import 누락, 인터페이스 구현 누락, Solidity 버전 충돌 등을 잡습니다. 이후 모든 게이트의 전제조건입니다.

---

### 2. Slither 정적 보안 분석

| 항목 | 값 |
|------|---|
| 스크립트 | `scripts/gates/check_slither_gate.py` |
| 도구 | Trail of Bits의 [Slither](https://github.com/crytic/slither) |
| 실패 기준 | `medium` 이상 (환경변수 `SLITHER_FAIL_LEVEL`로 조정 가능) |
| 범위 | `protocol/src/`만 (test, lib, upstream 제외) |

모든 프로덕션 컨트랙트를 대상으로 Slither를 실행하며, 설정된 심각도 이상의 발견이 있으면 FAIL합니다.

**잡아내는 것들:**
- 리엔트런시(재진입) 취약점
- 검증되지 않은 외부 호출
- 접근 제어 누락
- 미사용 상태 변수
- 위험한 산술 패턴

---

### 3. Storage Layout (스토리지 레이아웃)

| 항목 | 값 |
|------|---|
| 스크립트 | `scripts/gates/check_storage_layout.py` |
| 기준 | 고정 커밋 `ee547b17...`의 업스트림 Uniswap V2 Pair |

`forge inspect <contract> ... storageLayout`를 사용하여 업스트림 `UniswapV2Pair`와 현재 `NadSwapV2Pair`의 스토리지 레이아웃을 비교합니다.

**강제하는 2가지 불변조건:**

1. **V2 필드 보존** — `reserve0`, `reserve1`, `blockTimestampLast`, `price0CumulativeLast`, `price1CumulativeLast`, `kLast`, `unlocked` 7개 필드의 slot, offset, type이 업스트림과 **100% 동일**해야 합니다.
2. **NadSwap 필드는 append-only** — `quoteToken`, `buyTaxBps`, `sellTaxBps`, `initialized`, `taxCollector`, `accumulatedQuoteTax` 6개 필드는 V2 마지막 필드 **이후** 슬롯에 배치되어야 합니다.

업스트림 Git HEAD가 고정된 커밋 SHA 및 provenance 파일과 일치하는지도 검증합니다.

**왜 중요한가:** V2 슬롯 사이에 필드를 삽입하면 이후 모든 스토리지가 밀려서 라이브 데이터가 완전히 깨집니다.

---

### 4. P0 Smoke Gate (swap/tax guard 경로)

| 항목 | 값 |
|------|---|
| 명령어 | `forge test --match-path "test/core/PairSwapGuards.t.sol"` 후 `forge test --match-path "test/core/PairFlashQuote.t.sol"` |
| 우선순위 | P0 — 다른 모든 테스트 게이트보다 먼저 실행 |

가장 중요한 swap guard 및 flash-quote 테스트 파일을 다른 테스트 스위트보다 **먼저** 실행하여, 세금 트리거 및 guard 경로 로직에 대한 빠른 실패 피드백을 제공합니다.

**핵심 truth-table 회귀 테스트:**
- `test_trigger_buyTax_only_when_quoteIn_and_baseOut` — 매수 세금이 Quote → Base (quote-in, base-out) 방향일 **때만** 발생하는지 검증. 다른 방향에서는 세금이 트리거되지 않음을 보장.
- `test_trigger_sellTax_only_when_quoteOut` — 매도 세금이 quote 토큰이 유출될 **때만** 발생하는지 검증. flash 스타일 상환으로 매도 방향을 격리.

이 두 테스트는 4가지 가능한 (방향 × 세금 유형) 매트릭스 항목을 커버하는 **truth-table 회귀 테스트**를 형성하여, 세금 트리거 조건이 실수로 반전되거나 확대되는 것을 방지합니다.

---

### 5 & 7. Invariant Tests (불변조건 테스트)

| 항목 | Gate 5 (경량) | Gate 7 (심층) |
|------|-------------|--------------|
| 프로파일 | 기본 | `invariant-nightly` |
| 깊이 | 표준 | 높음 |
| 목적 | 빠른 스모크 테스트 | 심층 탐색 |

Foundry의 불변조건 테스트는 컨트랙트 함수를 **랜덤 순서, 랜덤 파라미터로 호출**한 뒤, 매 호출 후 불변조건이 유지되는지 체크합니다.

**테스트되는 불변조건 예시:**
- 모든 스왑 후 K(effective) ≥ K_old
- vault ≤ raw quote balance가 항상 성립
- reserves == effective balances
- LP 총 공급량이 풀 상태와 일관성 유지

예상치 못한 호출 순서(예: mint → swap → burn → swap → claim 연속)에서만 드러나는 버그를 잡습니다.

---

### 6. Unit / Fuzz / Regression (유닛·퍼즈·회귀 테스트)

| 항목 | 값 |
|------|---|
| 명령어 | `forge test --no-match-path "test/{fork,invariant}/**"` |
| 개수 | ~107개 테스트 (strict 기준) |

fork와 invariant를 제외한 모든 테스트를 실행합니다:

| 파일 | 검증 범위 |
|------|---------|
| `Factory.t.sol` | Pair 생성, 중복 방지, 접근 제어 |
| `FactoryAdminExt.t.sol` | 세금 설정 변경, quote 토큰 관리 |
| `PairLifecycle.t.sol` | mint → swap → burn 전체 라이프사이클 |
| `PairSwap.t.sol` | 매수/매도 스왑, 세금 적립, vault 축적 |
| `PairSwapGuards.t.sol` | 가드 조건, P0 truth-table 세금 트리거, vault 오버플로, K 오버플로 |
| `PairFlashQuote.t.sol` | Flash swap 엣지 케이스 |
| `ClaimTaxAdvanced.t.sol` | 세금 청구, 리엔트런시 방어, vault 리셋 |
| `Regression.t.sol` | 이전에 발견된 버그가 재발하지 않는지 |
| `PairKOverflowDomain.t.sol` | 대형 도메인 퍼즈: 2¹⁰⁸–2¹¹¹ 리저브에서 K-invariant 및 K_MULTIPLY_OVERFLOW |
| `FuzzInvariant.t.sol` | 퍼즈 기반 수학적 속성 검증 |
| `RouterLibrary.t.sol` | Library 계산 함수 정확성 |
| `RouterQuoteParity.t.sol` | Router 견적 vs 실제 실행 일치 |
| `PolicyEnforcement.t.sol` | Router 정책 적용 (quote 토큰 검증 등) |

퍼즈 테스트는 극단적인 값(0, 1, max uint 등)을 포함한 랜덤 입력을 테스트당 64~256번 실행합니다.

---

### 8. Nightly Large-Domain K/Overflow Fuzz (대형 도메인 K/오버플로 퍼즈)

| 항목 | 값 |
|------|---|
| 파일 | `protocol/test/core/PairKOverflowDomain.t.sol` |
| 프로파일 | `invariant-nightly` |
| 퍼즈 실행 횟수 | 테스트당 1,024회 |
| 리저브 범위 | 2¹⁰⁸ – 2¹¹¹ (대칭) |

**대형 리저브 도메인**(2¹⁰⁸ ~ 2¹¹¹, 일반적인 18 소수점 토큰 풀을 훨씬 초과)에서 K-invariant와 오버플로 가드를 스트레스 테스트하는 전용 퍼즈 게이트.

**테스트:**

| 테스트 | 목적 |
|--------|-----|
| `testFuzz_largeDomain_buy_kInvariant_holds` | 대형 리저브에서 매수 스왕 후 K가 절대 감소하지 않음. low/mid/high/ultra-large 버킷 입력. |
| `testFuzz_largeDomain_sell_kInvariant_holds` | 대형 리저브에서 매도 스왕 후 K가 절대 감소하지 않음. 매도는 리저브의 1%로 제한. |
| `testFuzz_largeAmount_sell_revertsWithKMultiplyOverflow` | 거대한 base-in 금액(2²²⁰–2²⁴⁰)이 조용히 wrapping하지 않고 `K_MULTIPLY_OVERFLOW`로 올바르게 revert. |

1,024회 퍼즈 반복을 통해 uint112 전체 도메인에서 K-check와 오버플로 가드가 유지된다는 높은 통계적 신뢰성을 제공합니다.

---

### 9. Math Consistency (수학적 일관성 — Python 교차 검증)

| 항목 | 값 |
|------|---|
| 스크립트 | `scripts/gates/check_math_consistency.py` (677줄) |
| 벡터 수 | ~1,386개 |
| 언어 | Python (임의 정밀도 정수 연산) |

가장 정교한 게이트입니다. **Pair의 swap 로직을 Python으로 완전히 재구현**한 뒤, Library 견적과 Pair 실행이 수학적으로 일치하는지 검증합니다.

**4가지 방향 검증:**

| # | 방향 | 방법 | 검증 조건 |
|---|------|------|---------|
| 1 | 매수 exact-in (Quote→Base) | `getAmountsOut` → Pair 시뮬 | 세금 일치, K 통과 |
| 2 | 매도 exact-in (Base→Quote) | `getAmountsOut` → Pair 시뮬 | gross/net 차이 ≤ 1 wei |
| 3 | 매도 exact-out (Base→Quote) | `getAmountsIn` → Pair 시뮬 | gross 정확 일치 |
| 4 | 매수 exact-out (Quote→Base) | `getAmountsIn` → Pair 시뮬 | effIn ≥ lib (LP에 유리) |

**테스트 벡터 조합:**
- 리저브: 6가지 (극단적 불균형, 대규모, 소규모 등)
- 세금률: 7가지 (0/0 ~ 2000/2000)
- Quote 위치: 2가지 (token0=Quote / token1=Quote)
- 금액 비율: 5가지 (리저브의 0.1%~30%)

**추가 서브테스트:**
- **경계값**: Buy tax가 0 → 1 wei로 전환되는 정확한 임계점
- **매도 라운드트립**: `floor → ceil` 변환 오차 ≤ 1 wei
- **K-invariant 스트레스**: 10¹⁸ 리저브에 대한 dust(1 wei) 입력, 연속 20번 스왑
- **uint96 vault 오버플로**: 실질적으로 불가능함을 수학적으로 증명
- **멀티홉 오차 누적**: 3-hop 경로에서 오차 N wei 이내

---

### 10. Traceability (추적성)

| 항목 | 값 |
|------|---|
| 스크립트 | `scripts/gates/check_traceability.py` |
| 추적 ID | FUZ-002, FUZ-003, REG-002, SEC-004, SEC-005 포함 (최근 추가) |
| 입력 | `NADSWAP_V2_REQUIREMENTS.yaml`, `NADSWAP_V2_TRACE_MATRIX.md`, `NADSWAP_V2_IMPL_SPEC_EN.md` |

모든 요구사항이 구현되어 있고, 테스트되고 있으며, 문서화되어 있는지를 보장합니다:

1. `REQUIREMENTS.yaml`의 모든 요구사항 ID에 대해 추적 행렬에 행이 존재하는지
2. 추적 행렬의 각 행이 실제 코드 경로를 참조하는지 (파일이 디스크에 존재)
3. 추적 행렬에서 참조하는 테스트 함수가 `protocol/test/`에 존재하는지
4. 각 행에 검증 명령어가 있는지
5. 스펙 Section 16의 `test_*` / `invariant_*` 이름이 Solidity 테스트에 존재하는지
6. 스펙에 명시된 테스트 이름이 추적 행렬 커버리지 테이블에 매핑되어 있는지
7. 추적 행렬에 스펙에 없는 추가 행이 없는지

---

### 11. Migration Checklist (마이그레이션 체크리스트)

| 항목 | 값 |
|------|---|
| 스크립트 | `scripts/gates/check_migration_signoff.py` |
| 입력 | `NADSWAP_V2_MIGRATION_SIGNOFF.md` |

**13개 마이그레이션 체크리스트 항목**(1~13번)이 모두 존재하는지 확인합니다. 이 항목들은 Uniswap V2 → NadSwap V2 포크 과정에서 변경된 사항의 전체 목록입니다 (수수료율 변경, 세금 메커니즘 추가, quote 토큰 개념, 접근 제어 변경 등).

---

### 12. Fork Test Suite (Monad 포크 테스트)

| 항목 | 값 |
|------|---|
| 스크립트 | `scripts/runners/run_fork_tests.sh` |
| 체인 | Monad 테스트넷 (RPC 포크) |
| 테스트 수 | 47개 |

**실제 Monad 테스트넷을 포크**하여 컨트랙트를 배포하고 모든 포크 전용 테스트를 실행합니다:

| 스위트 | 경로 | 테스트 수 |
|--------|------|---------|
| Core | `test/fork/core/` | 33 (lifecycle, swap, claim, factory policy) |
| Periphery | `test/fork/periphery/` | 11 (router parity, policy guards) |
| Fuzz Lite | `ForkFuzzLiteTest` | 3 (각 64번 실행) |

로컬 Anvil 테스트와 달리, 포크 테스트는 병렬 실행 등 차이점이 있는 Monad의 실제 EVM 구현 위에서 동작을 검증합니다.

---

## 게이트 이후 추가 단계

### 13. Collect Verification Metrics (메트릭 수집)

| 항목 | 값 |
|------|---|
| 스크립트 | `scripts/reports/collect_verification_metrics.py` |
| 출력 | `docs/reports/NADSWAP_V2_VERIFICATION_METRICS.json` |

모든 게이트 결과를 단일 JSON 메트릭 파일로 수집합니다:

| 메트릭 키 | 소스 | 예시 |
|----------|------|-----|
| `non_fork_all` | forge 테스트 출력 | 117 |
| `non_fork_strict` | forge 테스트 (fork + invariant 제외) | 112 |
| `fork_suite_total` | fork-logs 파싱 | 47 |
| `requirements_count` | YAML 요구사항 ID 수 | 30 |
| `spec_test_count` | 스펙 `test_*` 이름 수 | 90 |
| `spec_invariant_count` | 스펙 `invariant_*` 이름 수 | 5 |
| `math_consistency_total` | Python 검증 벡터 수 | 1386 |
| `migration_items_total` | 마이그레이션 항목 수 | 13 |

> 참고: `docs/reports/NADSWAP_V2_VERIFICATION_METRICS.json`은 현재 `protocol/` 기준 메트릭입니다.
> Lens suite 결과는 해당 메트릭 JSON에 별도 집계되지 않습니다.

환경 문제로 게이트를 실행할 수 없는 경우, 이전에 저장된 baseline 값으로 폴백합니다 (`BASELINE` 상태로 기록).

---

### 14. Render Verification Reports (리포트 렌더링)

| 항목 | 값 |
|------|---|
| 스크립트 | `scripts/reports/render_verification_reports.py` |
| 대상 | `NADSWAP_V2_SPEC_CONFORMANCE_REPORT.md`, `NADSWAP_V2_VERIFICATION_REPORT.md` |

수집된 메트릭을 리포트 파일의 `<!-- GENERATED:START -->` / `<!-- GENERATED:END -->` 블록에 주입합니다. `--check` 모드(게이트 실행 시 사용)에서는 렌더링 결과가 디스크의 파일과 다르면 FAIL — 오래된 리포트를 잡아냅니다.

---

### 15. Docs Symbol Refs (문서 심볼 참조)

| 항목 | 값 |
|------|---|
| 스크립트 | `scripts/gates/check_docs_symbol_refs.py` |
| 범위 | `docs/`의 모든 `.md` 파일 |

문서에서 `forge inspect <target> ... storageLayout` 명령어를 스캔하여:
- 참조된 컨트랙트 이름이 `protocol/src/`에 존재하는지
- 참조된 `.sol` 파일 경로가 디스크에 존재하는지

컨트랙트 이름 변경이나 파일 이동 후 문서 드리프트를 잡아냅니다.

---

### 16. Docs Consistency (문서 일관성)

| 항목 | 값 |
|------|---|
| 스크립트 | `scripts/gates/check_docs_consistency.py` |

가장 엄격한 문서 게이트. 여러 교차 검증을 수행합니다:

| 검증 | 설명 |
|------|------|
| **메트릭 드리프트** | JSON 메트릭 값이 실시간으로 집계한 소스 값과 일치해야 함 |
| **Claim 시맨틱** | 스펙에 올바른 claim 동작 설명이 있어야 하며, 오래된 표현은 금지 |
| **Tax 용어** | deprecated 용어 (`collector` 단독, `claimed quote fees`, `ClaimFeesAdvanced`) 금지 |
| **Fork 문서 모드** | 포크 테스트 문서에 Mode A (Runner)와 Mode B (Direct) 설명 필수 |
| **생성 블록 동기화** | 리포트의 GENERATED 블록이 최신 메트릭과 동기화되어야 함 |

---

## 오류 커버리지 매트릭스

| 오류 유형 | 잡아주는 게이트 |
|----------|---------------|
| 컴파일 실패 | Build |
| 리엔트런시 / 보안 취약점 | Slither |
| 스토리지 슬롯 손상 | Storage Layout |
| 세금 트리거 방향 반전 | P0 Smoke (truth-table 회귀) |
| 스왑 수학 ≥ 1 wei 오차 | Math Consistency |
| 대형 리저브(2¹⁰⁸–2¹¹¹)에서 K-invariant 위반 | Large-Domain K/Overflow Fuzz |
| K_MULTIPLY_OVERFLOW 무음 wrapping | Large-Domain K/Overflow Fuzz |
| 기존 테스트 회귀 | Unit / Fuzz / Regression |
| 예상 못한 호출 순서 불변조건 위반 | Invariant (둘 다) |
| 테스트 커버리지 없는 요구사항 | Traceability |
| 마이그레이션 체크리스트 항목 누락 | Migration |
| Monad 호환성 문제 | Fork Tests |
| 문서의 오래된 컨트랙트명 참조 | Docs Symbol Refs |
| 문서 내용과 코드 불일치 | Docs Consistency |
