# NadSwap V2 한눈에 보기

NadSwap V2는 Uniswap V2를 기반으로 만든 AMM(자동화 마켓메이커)입니다. 핵심 차이는 "거래세를 라우터가 아니라 코어 Pair 수학에 직접 넣었다"는 점입니다. 이 설계 덕분에 일반 UI 경로뿐 아니라 직접 컨트랙트 호출이나 MEV 경로에서도 동일한 세금 규칙이 적용됩니다.

이 문서는 비개발자에게는 "왜 필요한지, 무엇이 다른지, 왜 믿을 수 있는지"를, 개발자에게는 "V2 대비 어떤 동작이 바뀌었는지"를 빠르게 전달하기 위한 프로젝트 원페이저입니다.

## 1) 왜 이 프로젝트가 필요한가

런치 토큰 생태계에서는 거래세 정책이 자주 운영되지만, 많은 시스템이 라우터 레벨에서만 세금을 붙입니다. 이 경우 직접 Pair를 호출하거나 다른 라우팅 경로를 쓰면 정책을 우회할 여지가 생깁니다. 결과적으로 사용자마다 체감 수수료가 달라지고, 프로젝트 운영자는 정책 일관성을 유지하기 어려워집니다.

NadSwap V2는 이 문제를 "호출 경로가 아니라 코어 수학"에서 해결합니다. 즉, 어떤 경로로 스왑을 실행해도 Pair `swap()` 내부에서 같은 규칙이 적용되도록 설계해 우회 가능성을 구조적으로 낮췄습니다.

## 2) NadSwap이 해결하는 방식

아래 4가지 원칙이 NadSwap V2의 핵심입니다.

| 원칙 | 쉬운 설명 |
|---|---|
| 코어 강제 (Core Enforcement) | 세금을 UI/라우터가 아니라 Pair `swap()` 내부에서 계산합니다. |
| Tax Vault | 세금을 매번 외부 전송하지 않고 Pair 내부 장부(`accumulatedQuoteTax`)에 누적합니다. |
| 역산 수학 (Reverse Math) | 사용자가 받을 Net 기준으로 내부 Gross를 역산해, 표시값과 실행값의 차이를 줄입니다. |
| Effective Reserve | `raw - taxVault` 기준으로 reserve를 관리해 LP 자산과 세금 자산을 분리 회계합니다. |

비개발자 관점에서는 "경로가 달라도 규칙이 같다"가 핵심이고, 개발자 관점에서는 "K 검증과 reserve 업데이트를 effective 기준으로 일관되게 맞춘다"가 핵심입니다.

## 3) 사용자에게 주는 가치

- 공정성: 동일한 거래 조건에서 경로에 따른 세금 편차를 줄여 정책 체감이 일관됩니다.
- 예측 가능성: Quote/실행/정산의 기준이 문서화되어 있어 결과를 설명하기 쉽습니다.
- 운영 안정성: Lens 상태(`OK / INVALID_PAIR / DEGRADED`)를 통해 UI에서 위험 상태를 선제적으로 차단할 수 있습니다.

즉, "보이는 정책"이 아니라 "실행되는 정책"을 코어에 고정한 것이 NadSwap의 사용자 가치입니다.

## 4) 개발자 관점 핵심 차이 (Uniswap V2 대비)

| 항목 | Uniswap V2 | NadSwap V2 |
|---|---|---|
| `swap()` 흐름 | 6단계 중심 | 12단계로 확장(세금 계산, vault 반영, effective K 검증 포함) |
| LP 수수료 | 0.3% (`997/1000`) | 0.2% (`998/1000`) |
| Pair 생성 권한 | 무허가 `createPair` | `pairAdmin` 전용 `createPair` (세금 원자 초기화) |
| `pairFor` 방식 | INIT_CODE_HASH 기반 계산 | `factory.getPair` 조회 기반 |
| FOT 지원 엔트리포인트 | 지원 함수 존재 및 사용 가능 | FOT 관련 supporting 함수는 `FOT_NOT_SUPPORTED`로 hard-revert |

추가로, NadSwap V2는 듀얼 출력 swap 패턴을 거부해 방향 판정과 세금 회계를 단순·명확하게 유지합니다.

## 5) 신뢰성 근거 (숫자로 보는 검증)

아래 수치는 `docs/reports/NADSWAP_V2_VERIFICATION_REPORT.md`의 **2026-02-14 보고서**와, 같은 문서의 GENERATED 블록에 표기된 **2026-02-15 메트릭 스냅샷** 기준입니다.

| 검증 항목 | 결과 |
|---|---|
| Foundry tests (non-fork strict) | 112/112 PASS |
| Foundry tests (fork suites) | 47/47 PASS |
| Foundry tests (non-fork all) | 117/117 PASS |
| Traceability requirements | 30/30 PASS |
| Spec named tests | 90/90 PASS |
| Spec named invariants | 5/5 PASS |
| Math consistency vectors | 1,386/1,386 PASS |
| Migration checklist items | 13/13 PASS |

핵심은 단순 테스트 통과가 아니라, 요구사항-코드-테스트-문서 정합성까지 게이트로 확인한다는 점입니다.

## 6) 현재 제약과 운영 원칙

- FOT/리베이싱 토큰은 지원 대상이 아닙니다. 관련 supporting 함수는 명시적으로 차단됩니다.
- Base 토큰은 온체인 allowlist를 강제하지 않으므로, 운영상 `pairAdmin`이 표준 ERC20(비FOT/비리베이싱)만 상장해야 합니다.
- 포크 검증은 RPC/chainId/block 환경이 정확해야 하며, 환경 누락 시 실패가 정상 동작입니다.

이 제약은 기능 부족이라기보다, 회계 불변식과 예측 가능한 실행 결과를 지키기 위한 설계 선택입니다.

## 7) 어디서 바로 확인할 수 있나

- 구현 명세(KR): [`docs/NADSWAP_V2_IMPL_SPEC_KR.md`](./NADSWAP_V2_IMPL_SPEC_KR.md)
- 구현 명세(EN): [`docs/NADSWAP_V2_IMPL_SPEC_EN.md`](./NADSWAP_V2_IMPL_SPEC_EN.md)
- 검증 리포트: [`docs/reports/NADSWAP_V2_VERIFICATION_REPORT.md`](./reports/NADSWAP_V2_VERIFICATION_REPORT.md)
- Traceability 매트릭스: [`docs/traceability/NADSWAP_V2_TRACE_MATRIX.md`](./traceability/NADSWAP_V2_TRACE_MATRIX.md)
- Lens 가이드(KR): [`docs/lens/NADSWAP_LENS_V1_1_GUIDE_KR.md`](./lens/NADSWAP_LENS_V1_1_GUIDE_KR.md)
- Lens 문서 인덱스: [`docs/lens/README.md`](./lens/README.md)
- 앱 빠른 실행 안내: [`apps/nadswap/README.md`](../apps/nadswap/README.md)

빠르게 로컬에서 확인하려면 아래 순서를 사용하면 됩니다.

```bash
pnpm setup
pnpm local:up
pnpm test:local
```
