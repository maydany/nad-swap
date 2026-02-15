# NadSwap V2

> **토큰 런치 거래세를 코드로 강제하는 AMM**  
> Uniswap V2 최소 수정 · 코어 강제 세금 모델 · 재현 가능한 검증 자동화

<table>
<tr>
<td><strong>📘 구현 명세 (KR)</strong></td>
<td><a href="docs/NADSWAP_V2_IMPL_SPEC_KR.md">docs/NADSWAP_V2_IMPL_SPEC_KR.md</a></td>
</tr>
<tr>
<td><strong>📘 구현 명세 (EN)</strong></td>
<td><a href="docs/NADSWAP_V2_IMPL_SPEC_EN.md">docs/NADSWAP_V2_IMPL_SPEC_EN.md</a></td>
</tr>
<tr>
<td><strong>🔍 Lens 문서</strong></td>
<td><a href="docs/lens/README.md">docs/lens/README.md</a></td>
</tr>
<tr>
<td><strong>✅ 검증 리포트</strong></td>
<td><a href="docs/reports/NADSWAP_V2_VERIFICATION_REPORT.md">docs/reports/NADSWAP_V2_VERIFICATION_REPORT.md</a></td>
</tr>
<tr>
<td><strong>🔀 Migration Signoff</strong></td>
<td><a href="docs/reports/NADSWAP_V2_MIGRATION_SIGNOFF.md">docs/reports/NADSWAP_V2_MIGRATION_SIGNOFF.md</a></td>
</tr>
</table>

---

## TL;DR

Uniswap V2를 포크하여 **Pair `swap()` 수학 내부에 buy/sell 거래세를 내장**한 AMM입니다.

**V2에서 유지한 것:**
- K-invariant 구조, `_mintFee`, TWAP, `lock` reentrancy guard, 전체 Router 시그니처
- 스토리지 레이아웃 (추가 변수는 V2 원본 뒤에 append-only)

**V2에서 변경한 것:**
- `swap()` 6단계 → 12단계 (세금 계산·tax vault 적립·effective balance 기반 K 검증)
- LP 수수료 0.3% → 0.2% (거래세와의 총비용 균형)
- `createPair`를 `pairAdmin` 전용으로 변경 (세금 원자적 초기화)
- `pairFor`를 `factory.getPair` 조회로 변경 (INIT_CODE_HASH 의존 제거)
- 듀얼 출력 swap 거부, FOT 엔트리포인트 hard-revert

**주요 트레이드오프:**
- 듀얼 출력 플래시 패턴 미지원 → 코어 단순성·세금 방향 판정 명확성 확보
- 무허가 pair 생성 불가 → tax=0 윈도우 공격 차단
- FOT/리베이싱 토큰 미지원 → `raw = reserve + taxVault` 회계 불변식 보호

---

## 설계 철학

### 목표

토큰 런치 시나리오에서 **거래세 우회를 구조적으로 불가능**하게 만드는 것이 핵심 목표입니다. Router 수준의 세금 부과는 직접 Pair 호출, MEV 봇, 커스텀 라우터 등으로 쉽게 우회됩니다. NadSwap은 세금을 Pair의 `swap()` 수학 자체에 내장하여, **어떤 경로로 호출하든 세금이 부과**되도록 설계했습니다.

### 4가지 원칙

| 원칙 | 한 줄 요약 |
|------|-----------|
| 코어 강제 | 세금 로직을 Pair `swap()` 내부에 내장 |
| Tax Vault | 세금을 장부에 누적, ERC20 전송 생략 |
| 역산 수학 | 사용자 Net 기준으로 내부 Gross를 역산 |
| Effective Reserve | Reserve를 `raw - taxVault` 기준으로 관리 |

**코어 강제 (Core Enforcement):** 세금 로직을 Router가 아닌 Pair `swap()` 수학 내부에 배치합니다. 대안으로 Router에서 세금을 부과하는 방식(V2 FOT 패턴)이 있지만, 이는 Router를 우회하는 직접 호출을 막을 수 없습니다. 코어 내장 방식은 Pair 코드의 복잡성이 증가하는 트레이드오프가 있지만, 우회 불가능이라는 보안 보장을 얻습니다.

**Tax Vault:** 매 스왑에서 세금을 즉시 ERC20 전송하지 않고, `accumulatedQuoteTax` 상태 변수에 장부 적립합니다. 이로써 스왑당 ~21,000 gas를 절감합니다. 트레이드오프는 `taxCollector`가 별도로 `claimQuoteTax()`를 호출해야 세금을 수령할 수 있다는 점이며, claim은 reserve를 재동기화하지 않으므로 quote dust는 skimmable 상태로 유지됩니다.

**역산 수학 (Reverse Math):** sell 방향에서 사용자가 수령할 Net 금액을 기준으로, Pair 내부에서 세금 포함 Gross 금액을 ceil 역산합니다. Library quote는 `net = floor(grossOut × (BPS-sellTax) / BPS)`를 직접 사용하며, 역산 라운드트립(`floor→ceil`) 오차는 최대 1 wei로 제한됩니다.

**Effective Reserve 원칙:** Reserve에는 tax vault를 포함하지 않은 `effective = raw - taxVault`만 저장합니다. tax vault 적립금은 LP가 아닌 taxCollector의 자산이므로, TWAP·feeTo·LP 정산을 LP 실제 자산 기준으로 일관되게 유지합니다. 모든 경로(`swap`/`mint`/`burn`/`skim`/`sync`)가 이 원칙을 따릅니다.

> 상세 구현 명세: [docs/NADSWAP_V2_IMPL_SPEC_KR.md](docs/NADSWAP_V2_IMPL_SPEC_KR.md)

---

## Uniswap V2와의 차이점 (Diff 총정리)

> Uniswap V2를 알고 있는 개발자라면, 이 섹션만 읽으면 NadSwap V2를 이해할 수 있습니다.
> 변경은 **4개 계약** 전체에 걸쳐 있으며, 모두 하나의 설계 목표—**코어 레벨 세금 강제**—에서 비롯됩니다.

전체 마이그레이션 체크리스트(13개 항목): [NADSWAP_V2_MIGRATION_SIGNOFF.md](docs/reports/NADSWAP_V2_MIGRATION_SIGNOFF.md)  
ABI 변경 상세: [NADSWAP_V2_ABI_DIFF.md](docs/abi/NADSWAP_V2_ABI_DIFF.md)

---

### 0. 새로 도입된 역할과 개념

아래는 Uniswap V2에 존재하지 않는, NadSwap이 새로 도입한 역할과 개념입니다. 이후 설명에서 반복적으로 등장하므로 먼저 정리합니다.

| 역할/개념 | 소속 | 설명 |
|-----------|------|------|
| `pairAdmin` | Factory | 유일한 관리자. pair 생성, 세율 변경, Quote 화이트리스트, `feeTo` 설정 권한. 배포 시 고정, 이후 변경 불가 |
| `taxCollector` | Pair | 누적된 세금을 수령하는 주소. pair별 설정, `pairAdmin`이 변경 가능 |
| Quote 토큰 | Pair | pair당 정확히 1개. 세금이 이 토큰으로만 누적됨 (예: WETH, USDT) |
| Base 토큰 | Pair | Quote의 상대 토큰. 온체인 allowlist 강제 없음(운영정책으로 표준 ERC20만 생성) |
| Tax Vault | Pair | `accumulatedQuoteTax` — 누적 세금 잔고. ERC20 전송 없이 장부 적립 |

**권한 구조:**
- `pairAdmin` → `createPair()`, `setTaxConfig()`, `setQuoteToken()`, `setFeeTo()` 호출 가능
- `taxCollector` → `claimQuoteTax()` 호출 가능

**V2의 `feeToSetter`와의 차이:** V2에서는 `feeToSetter`가 `feeTo` 주소만 관리합니다. NadSwap에서는 `feeToSetter` 역할을 제거하고, 모든 관리 권한을 `pairAdmin` 하나로 통합했습니다. pair 생성·세율·Quote 화이트리스트·`feeTo` 설정을 단일 관리자가 담당하여 권한 모델을 단순화합니다.

> **용어 정리 — tax vs fee:** 이 문서에서는 거래세를 **tax**로 통일합니다. tax 관련 코드 식별자는 `accumulatedQuoteTax`, `taxCollector`, `claimQuoteTax`로 명확히 분리합니다. LP 수수료는 K-invariant 수학에 내장되어 있고, tax는 tax vault에 별도 적립됩니다.

---

### 1. 회계 모델 변경 — 모든 변경의 근원

V2와의 가장 근본적인 차이입니다. 이 모델을 먼저 이해해야 이후의 변경이 왜 필요한지 자연스럽게 따라옵니다.

```
V2:      rawBalance == reserve                        (+ skim-able dust)
NadSwap: rawBalance == reserve + taxVault(누적 세금)   (+ skim-able dust)
         effective  == rawBalance - taxVault
```

V2에서는 Pair 계약에 있는 토큰 잔고(`rawBalance`)가 곧 LP의 reserve입니다. NadSwap에서는 세금이 ERC20으로 전송되지 않고 Pair 내부에 장부로 남아 있으므로, `rawBalance`에는 LP의 자산(reserve)과 taxCollector의 자산(tax vault)이 함께 들어 있습니다.

**Effective Balance** = `rawBalance - taxVault`로, LP가 실제로 소유한 자산만을 의미합니다. NadSwap의 모든 경로는 이 값을 기준으로 동작합니다:

- **Reserve** → 항상 effective 기준으로 저장. TWAP, feeTo, LP 정산이 tax vault와 분리됨
- **K-invariant** → effective balance 기준으로 검증
- **Swap 이벤트** → effective input을 emit (raw가 아님)
- **mint / burn / skim / sync** → 모두 effective balance 기준
- **Tax Vault** → 장부 적립이므로 스왑마다 ERC20 전송이 불필요 (가스 ~21,000 절감)

---

### 2. Factory (`UniswapV2Factory`)

#### 1-1. `createPair` 시그니처 변경 + 접근 제어

```diff
 // Uniswap V2
-function createPair(address tokenA, address tokenB)
-    external returns (address pair);
 // NadSwap V2
+function createPair(
+    address tokenA, address tokenB,
+    uint16 buyTaxBps, uint16 sellTaxBps,
+    address taxCollector
+) external returns (address pair);
+// require(msg.sender == pairAdmin)
```

| 항목 | V2 | NadSwap |
|------|-----|---------|
| 호출자 | 누구나 | `pairAdmin` only |
| 인자 | 2개 (tokenA, tokenB) | 5개 (+buyTax, sellTax, taxCollector) |
| 시그니처 | `createPair(address,address)` | `createPair(address,address,uint16,uint16,address)` |

Pair 생성과 세금 설정을 **원자적으로 초기화**해야 무세금 거래 구간(tax=0 윈도우)과 pair 선점 공격을 방지할 수 있습니다. `pairAdmin` 접근 제어는 무허가 pair 생성으로 인한 front-running을 차단합니다.

#### 1-2. Constructor를 단일 `pairAdmin`으로 변경

```diff
 // V2
-constructor(address _feeToSetter) public
 // NadSwap
+constructor(address _pairAdmin) public
```

V2의 `feeToSetter` 역할을 제거하고, `pairAdmin` 하나로 모든 관리 권한을 통합했습니다. `pairAdmin`은 배포 시 고정되며, 이후 변경 함수(`setPairAdmin`)는 존재하지 않습니다.

#### 1-3. Quote 토큰 화이트리스트 — 새로 추가

NadSwap은 pair 당 **정확히 1개의 Quote 토큰**(WETH, USDT 등)을 가지며, 세금은 Quote로만 적립됩니다.

| 추가된 상태 | 역할 |
|------------|------|
| `mapping(address => bool) isQuoteToken` | Quote 화이트리스트. `pairAdmin`이 관리 |
| `mapping(address => bool) isPair` | 이 Factory가 생성한 pair 무결성 확인용 레지스트리 |
| `address pairAdmin` | pair 생성·세율 변경 권한자 |

**createPair 시 추가 검증:**
- `BOTH_QUOTE` — 두 토큰이 모두 quote이면 revert (pair당 quote는 정확히 1개)
- `QUOTE_REQUIRED` — 둘 중 하나는 반드시 quote여야 함
- Base 토큰은 별도 allowlist 없이 생성 가능(quote 조건만 강제)
- 운영정책: `pairAdmin`은 Base를 비FOT/비리베이싱 표준 ERC20으로만 생성

#### 1-4. `setTaxConfig` — 새로 추가 (Factory 경유)

```solidity
function setTaxConfig(address pair, uint16 buy, uint16 sell, address taxCollector) external;
// require(msg.sender == pairAdmin)
// require(isPair[pair])  -- onlyValidPair modifier
```

`pairAdmin`이 배포 후 언제든 pair의 세율과 collector를 변경할 수 있습니다.

---

### 2. Pair (`UniswapV2Pair`)

#### 2-1. 추가된 상태 변수 (2 슬롯)

V2 원본 상태 변수(`token0` … `unlocked`)의 **뒤에 append-only**로 추가됩니다. V2 슬롯 오프셋은 보존됩니다.

```solidity
// ── Slot K (200 bits used, 56 bits free) ──
address public quoteToken;             // pair 생성 시 고정
uint16  public buyTaxBps;              // buy 세율 (bps, 최대 2000 = 20%)
uint16  public sellTaxBps;             // sell 세율 (bps, 최대 2000, < 10000)
bool    private initialized;           // 1회 초기화 플래그

// ── Slot K+1 (256 bits perfect packing) ──
address public taxCollector;           // 세금 수령자
uint96  public accumulatedQuoteTax;   // Virtual Vault (장부 누적 세금)
```

#### 2-2. `initialize` 시그니처 확장

```diff
 // V2
-function initialize(address _token0, address _token1) external
 // NadSwap
+function initialize(
+    address _token0, address _token1,
+    address _quoteToken,
+    uint16 _buyTaxBps, uint16 _sellTaxBps,
+    address _taxCollector
+) external
```

V2에서는 token0/token1만 설정하지만, NadSwap에서는 quote 식별·세율·collector까지 **1회 원자적으로 초기화**합니다. `initialized` 플래그로 재호출을 차단합니다.

#### 2-3. `swap()` — 12단계 알고리즘으로 확장

V2의 swap은 6단계(검증→전송→잔고→입력계산→K확인→저장)입니다.  
NadSwap은 이를 **12단계**로 확장하여 세금 계산을 수학 내부에 내장합니다:

| V2 | NadSwap | 변경 |
|----|---------|------|
| 1. 기본 검증 | 1. 기본 검증 | |
| | 2. 단일측 출력 강제 | NEW |
| 3. 유동성 확인 | 3. 유동성 확인 (Net 기준) | |
| 4. 전송 + 콜백 | 4. Net 전송 + 콜백 | |
| 5. 잔고 조회 | 5. Raw 잔고 조회 | |
| | 6. oldVault 기준 effective 계산 | NEW |
| | 7. 방향 판정 + sell 세금 | NEW |
| 6. amountIn 계산 | 8. amountIn 계산 + buy 세금 | MOD |
| | 9. newVault 업데이트 | NEW |
| | 10. newVault 기준 effective 재계산 | NEW |
| 7. K 불변식 확인 | 11. K 불변식 (998/1000) | MOD |
| 8. 저장 + 이벤트 | 12. taxVault + reserve + 이벤트 | MOD |

**핵심 차이점 요약:**

| 관점 | V2 | NadSwap |
|------|-----|---------|
| 세금 | 없음 | buy: 입력 선공제 (floor), sell: 출력 역산 (ceil) |
| 잔고 기준 | raw balance | effective = raw - taxVault |
| 듀얼 출력 | 허용 (amount0Out > 0 && amount1Out > 0) | **거부** (`SINGLE_SIDE_ONLY`) |
| K 상수 | `997/1000` (0.3% fee) | `998/1000` (0.2% fee) |
| Swap 이벤트 입력 | raw amountIn | effective amountIn (newVault 반영) |
| Tax Vault 누적 | N/A | `accumulatedQuoteTax += taxIn + taxOut` |

**듀얼 출력 거부 — 트레이드오프 상세:**

NadSwap은 `swap(amount0Out, amount1Out, ...)` 호출에서 양쪽 출력을 동시에 요청하면 `SINGLE_SIDE_ONLY`로 revert합니다. 이는 V2와의 **가장 큰 동작 비호환**이며, 의도적인 트레이드오프입니다.

- **플래시 스왑**: 두 토큰을 동시에 빌리는 듀얼 출력 플래시 론이 불가능합니다. 단일측 빌림은 여전히 가능하므로 플래시 론 자체가 사라지는 것은 아니지만, 듀얼 출력 패턴은 리팩토링이 필요합니다.
- **아비트라지 봇**: V2 대상 `swap(a, b, ...)` 형태의 듀얼 출력 전략은 동작하지 않습니다. 단일측 swap으로 분리해야 합니다.
- **MEV/샌드위치**: 듀얼 출력 제한으로 공격 표면이 줄어드는 부수적 보안 효과가 있습니다.
- **통합**: V2 기반 aggregator(1inch, Paraswap 등)가 NadSwap pair를 경유할 때 듀얼 출력 호출 경로를 제거해야 합니다.

세금 방향(buy/sell)은 "어느 쪽이 quote 출력인가"로 판정합니다. 양쪽이 동시에 출력이면 방향이 모호해지고, 세금을 정확히 부과할 수 없습니다. 이를 해결하려면 (1) 듀얼 출력 시 별도 방향 판정 로직을 추가하거나 (2) 두 방향 세금을 모두 부과하는 등의 복잡한 처리가 필요한데, 이는 코어의 단순성과 감사 용이성을 해칩니다. V2 생태계에서 듀얼 출력 swap의 실제 사용 빈도가 낮고, NadSwap의 주요 사용 패턴(토큰 런치 AMM)에서는 필요성이 거의 없으므로, **코어 단순성을 보존하는 쪽을 선택**했습니다.

#### 2-4. 세금 수학 — 두 가지 방향

**Buy (Quote→Base, Quote가 Input)** — 선공제, floor:
```
quoteTaxIn  = ⌊ quoteInRaw × buyTaxBps / BPS ⌋
quoteInNet  = quoteInRaw - quoteTaxIn
→ tax vault에 quoteTaxIn 적립
```

**Sell (Base→Quote, Quote가 Output)** — 역산, ceil:
```
quoteOutGross = ⌈ quoteOutNet × BPS / (BPS - sellTaxBps) ⌉
quoteTaxOut   = quoteOutGross - quoteOutNet
→ tax vault에 quoteTaxOut 적립, 사용자에게는 Net만 전송
```

Router가 인용(quote)한 Net 수량을 사용자에게 **정확히** 전달하기 위해, 내부적으로 세금 포함 Gross를 역산합니다. 사용자는 Net만 수령하며, 차액(tax)은 tax vault에 장부 적립됩니다.

#### 2-5. `mint` / `burn` / `skim` / `sync` — effective balance 기준

V2에서는 raw balance를 직접 사용하지만, NadSwap에서는 **모든 경로**가 effective balance (`rawBalance - taxVault`)를 사용합니다.

| 함수 | V2 | NadSwap |
|------|-----|---------|
| `mint` | `amount = balance - reserve` | `amount = effBalance - reserve` (tax vault 제외) |
| `burn` | LP 비례 = raw 기준 | LP 비례 = effective 기준 (tax vault는 LP 자산이 아님) |
| `skim` | `excess = balance - reserve` | `expected = reserve + taxVault`, `excess = raw > expected ? raw - expected : 0` |
| `sync` | `_update(balance0, balance1)` | `_update(effBalance0, effBalance1)` |

Tax vault 적립금은 LP가 아닌 taxCollector의 자산입니다. Reserve에 tax vault를 혼재시키면 LP 정산, TWAP, feeTo 모두 왜곡됩니다.

#### 2-6. `claimQuoteTax` — 새로 추가

```solidity
function claimQuoteTax(address to) external lock;
// require(msg.sender == taxCollector)
```

`taxCollector`가 누적된 quote 세금을 수령합니다. Claim은 tax vault만 0으로 리셋하고 reserve/TWAP는 건드리지 않습니다.

> **참고**: claim 시점의 quote 측 dust(직접 전송 등으로 발생한 미량)는 reserve에 편입되지 않고 그대로 유지됩니다. dust는 `skim`으로 회수할 수 있으며, 이후 `sync`/`swap`/`mint`/`burn` 경로에서만 reserve 반영이 일어날 수 있습니다.

#### 2-7. `setTaxConfig` — 새로 추가 (Factory 경유)

```solidity
function setTaxConfig(uint16 _buyTaxBps, uint16 _sellTaxBps, address _collector) external;
// require(msg.sender == factory)
```

세율과 collector를 하나의 트랜잭션으로 변경합니다. `pairAdmin`이 Factory를 경유하여 호출합니다.

#### 2-8. 추가된 이벤트

```solidity
event TaxConfigUpdated(uint16 buyTaxBps, uint16 sellTaxBps, address taxCollector);
event QuoteTaxAccrued(uint256 quoteTaxIn, uint256 quoteTaxOut, uint256 accumulatedQuoteTax);
event QuoteTaxClaimed(address indexed to, uint256 amount);
```

V2의 `Swap` 이벤트 시그니처는 동일하지만, **입력값의 의미가 다릅니다**: NadSwap은 newVault 반영 후의 effective input을 emit합니다. 인덱서는 이를 고려해야 합니다.

---

### 3. Library (`UniswapV2Library`)

#### 3-1. LP 수수료 상수 변경

```diff
 // getAmountOut
-uint amountInWithFee = amountIn * 997;
+uint amountInWithFee = amountIn * 998;

 // getAmountIn
-uint denominator = (reserveOut - amountOut) * 997;
+uint denominator = (reserveOut - amountOut) * 998;
```

LP 수수료가 **0.3% → 0.2%**로 변경되었습니다. K-invariant 정밀도(1000)는 V2 원형을 유지합니다.

NadSwap은 별도의 거래세를 부과하므로, LP 수수료를 낮춰 총 거래 비용을 합리적으로 유지합니다.

#### 3-2. `pairFor` — INIT_CODE_HASH 제거

```diff
 // V2: CREATE2 해시 기반 주소 파생
-function pairFor(address factory, address tokenA, address tokenB)
-    internal pure returns (address pair)
-{
-    pair = address(uint(keccak256(abi.encodePacked(
-        hex'ff', factory, keccak256(...), hex'96e8ac...'
-    ))));
-}

 // NadSwap: Factory 매핑 조회
+function pairFor(address factory, address tokenA, address tokenB)
+    internal view returns (address pair)
+{
+    pair = IUniswapV2Factory(factory).getPair(tokenA, tokenB);
+    require(pair != address(0), 'PAIR_NOT_FOUND');
+}
```

| 항목 | V2 | NadSwap |
|------|-----|---------|
| 함수 타입 | `pure` | `view` (외부 read) |
| 해싱 의존 | `INIT_CODE_HASH` 하드코딩 필요 | 없음 |
| 바이트코드 변경 영향 | 주소 드리프트 위험 | 없음 |

NadSwap의 Pair 바이트코드는 V2와 다릅니다. INIT_CODE_HASH를 하드코딩하면 Pair 계약이 변경될 때마다 Library도 함께 재배포해야 합니다. Factory 매핑 조회로 이 커플링을 제거합니다.

#### 3-3. `getAmountsOut` / `getAmountsIn` — 세금 인지형

V2에서는 순수 AMM 수학만 적용합니다. NadSwap에서는 **hop별로 buy/sell 세금을 반영**합니다:

| 경로 | 방향 | V2 | NadSwap |
|------|------|-----|---------|
| exact-in, Quote→Base (buy) | 입력 | `getAmountOut(rawIn)` | 세금 선공제 후 `getAmountOut` |
| exact-in, Base→Quote (sell) | 출력 | `getAmountOut(baseIn)` | `getAmountOut` 후 세금 후공제 |
| exact-out, Base→Quote (sell) | 역산 | `getAmountIn(netOut)` | gross-up 후 `getAmountIn` |
| exact-out, Quote→Base (buy) | 역산 | `getAmountIn(baseOut)` | `getAmountIn` 후 gross-up |

**공식 상세:**
- **buy exact-in**: `tax = ⌊ rawIn × buyTax / BPS ⌋`, `effIn = rawIn - tax` → `getAmountOut(effIn)`
- **sell exact-in**: `grossOut = getAmountOut(baseIn)` → `net = grossOut × (BPS-sellTax) / BPS`
- **sell exact-out**: `grossOut = ⌈ netOut × BPS / (BPS-sellTax) ⌉` → `getAmountIn(grossOut)`
- **buy exact-out**: `netIn = getAmountIn(baseOut)` → `rawIn = ⌈ netIn × BPS / (BPS-buyTax) ⌉`

> **주의**: sell exact-in에서 Library의 `grossOut`(floor)과 Pair의 역산 `grossOut`(ceil)은 최대 **1 wei** 차이가 날 수 있지만, 역산 gross는 항상 `grossOut`을 초과하지 않습니다.

---

### 4. Router (`UniswapV2Router02`)

#### 4-1. Auto-pair 생성 제거

```diff
 // V2: _addLiquidity 내부
-if (IUniswapV2Factory(factory).getPair(tokenA, tokenB) == address(0)) {
-    IUniswapV2Factory(factory).createPair(tokenA, tokenB);
-}

 // NadSwap
+require(IUniswapV2Factory(factory).getPair(tokenA, tokenB) != address(0), 'PAIR_NOT_CREATED');
```

V2에서는 최초 `addLiquidity` 시 pair가 자동 생성되지만, NadSwap에서는 **pairAdmin이 `createPair`로 사전 생성**해야 합니다. 미생성 pair에 유동성 공급을 시도하면 `PAIR_NOT_CREATED`로 revert합니다.

Pair 생성과 세금 초기화가 원자적이어야 "생성 직후 세금 0인 상태로 거래" 공격을 막을 수 있습니다.

#### 4-2. FOT-supporting 엔트리포인트 — 항상 revert

```solidity
// 아래 함수들은 ABI를 유지하지만, 런타임에서 항상 revert합니다:
function swapExactTokensForTokensSupportingFeeOnTransferTokens(...)  → revert('FOT_NOT_SUPPORTED')
function swapExactETHForTokensSupportingFeeOnTransferTokens(...)     → revert('FOT_NOT_SUPPORTED')
function swapExactTokensForETHSupportingFeeOnTransferTokens(...)     → revert('FOT_NOT_SUPPORTED')
function removeLiquidityETHSupportingFeeOnTransferTokens(...)        → revert('FOT_NOT_SUPPORTED')
function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(...)  → revert('FOT_NOT_SUPPORTED')
```

NadSwap의 Quote 세금 수학은 `rawBalance = reserve + taxVault` 불변식에 의존합니다. Quote-FOT/리베이싱은 이 불변식을 깨뜨리고, Base-FOT는 exact-in 경로 revert 또는 사용자 실수령 저하를 유발할 수 있습니다. ABI를 유지하는 이유는 호환성 도구가 함수 존재를 감지할 수 있게 하되, 실제 실행은 명시적으로 차단하기 위함입니다.

#### 4-3. `_requireSupportedPairTokens` — 새로 추가

```solidity
function _requireSupportedPairTokens(address pair, address tokenIn, address tokenOut) internal view {
    address qt = IUniswapV2Pair(pair).quoteToken();
    require(IUniswapV2Factory(factory).isQuoteToken(qt), 'QUOTE_NOT_SUPPORTED');
}
```

모든 swap/addLiquidity 경로에서 호출되어, quote 미지원 pair 경로를 차단합니다.



## 구현 개요

### Core / Periphery 매핑

| 개념 | 표준 계약명 | 구현 경로 |
|------|------------|----------|
| Factory | `UniswapV2Factory` | `protocol/src/core/NadSwapV2Factory.sol` |
| Pair | `UniswapV2Pair` | `protocol/src/core/NadSwapV2Pair.sol` |
| Library | `UniswapV2Library` | `protocol/src/periphery/libraries/NadSwapV2Library.sol` |
| Router | `UniswapV2Router02` | `protocol/src/periphery/NadSwapV2Router02.sol` |

### 저장소 구조

```
nad-swap/
├── apps/
│   └── nadswap/          # Vite + React 메인 dApp 프론트엔드
├── packages/
│   └── contracts/        # 프론트/도구 공통 ABI + 주소 타입
├── protocol/
│   ├── src/              # 프로토콜 구현 (Core + Periphery)
│   │   ├── core/         #   Factory, Pair, interfaces
│   │   └── periphery/    #   Router, Library
│   └── test/             # 테스트 스위트
│       ├── core/         #   Unit / Regression / Fuzz
│       ├── periphery/    #   Router 통합 테스트
│       ├── fork/         #   Monad 포크 검증
│       ├── invariant/    #   Stateful 불변식 테스트
│       └── helpers/      #   공용 테스트 유틸
├── lens/                 # NadSwap Lens V1.1 (별도 Foundry workspace)
│   ├── src/              #   Lens read-only contract
│   ├── test/             #   Unit + fork smoke
│   └── script/           #   Deployment script
├── scripts/
│   ├── gates/            # 자동화 게이트 (traceability, math, docs...)
│   ├── runners/          # 통합 실행기 (local gates, lens tests, fork tests)
│   │   ├── run_local_gates.sh
│   │   ├── run_lens_tests.sh
│   │   └── run_fork_tests.sh
│   └── reports/          # 메트릭 수집 / 리포트 렌더링
├── docs/                 # 명세, 리포트, 추적성 매트릭스
├── envs/                 # 환경 변수 템플릿 (.env.sh)
├── install_all_deps.sh   # 원커맨드 의존성 설치
├── run_all_tests.sh      # 원커맨드 전체 검증
└── deploy_local.sh       # Anvil 로컬 배포/데모
```

---

## 테스트/검증 범위

> **"100% 통과"를 넘어서, 코드-테스트-문서 정합성까지 자동 검증합니다.**

### 검증 지표 (기준일: 2026-02-15)

| 항목 | 결과 |
|------|------|
| Foundry tests (non-fork strict) | `112/112` ✅ |
| Foundry tests (fork suites) | `47/47` ✅ |
| Foundry tests (non-fork all) | `117/117` ✅ |
| Traceability requirements | `30/30` ✅ |
| Spec named tests | `90/90` ✅ |
| Spec named invariants | `5/5` ✅ |
| Math consistency vectors | `1,386/1,386` ✅ |
| Migration checklist items | `13/13` ✅ |

### 계층형 검증 구조

검증은 단일 레이어가 아니라 아래 계층을 **모두** 통과해야 합니다.

```
┌─────────────────────────────────────────────────┐
│  Layer 5 │ Docs Consistency                     │ ← 문서·심볼 참조 동기화
├──────────┤                                      │
│  Layer 4 │ Traceability                         │ ← 요구사항 ↔ 테스트 매핑
├──────────┤                                      │
│  Layer 3 │ Static Analysis (Slither)            │ ← 정적 분석 게이트
├──────────┤                                      │
│  Layer 2 │ Stateful Invariant · Fork            │ ← 상태 기반 불변식 + Monad 포크
├──────────┤                                      │
│  Layer 1 │ Unit · Regression · Fuzz             │ ← 개별 함수 수학 검증
└─────────────────────────────────────────────────┘
```

> **참고**: 위 수치는 `docs/reports` 기준일의 스냅샷입니다. 추후 테스트가 추가되더라도 기준일 명시로 해석 충돌을 방지합니다.

근거:
- [docs/reports/NADSWAP_V2_VERIFICATION_REPORT.md](docs/reports/NADSWAP_V2_VERIFICATION_REPORT.md)
- [docs/reports/NADSWAP_V2_VERIFICATION_METRICS.json](docs/reports/NADSWAP_V2_VERIFICATION_METRICS.json)
- [docs/traceability/NADSWAP_V2_TRACE_MATRIX.md](docs/traceability/NADSWAP_V2_TRACE_MATRIX.md)

---

## 시작하기

### 1) 의존성 설치
```bash
./install_all_deps.sh
# or
pnpm deps:all
```
> Foundry, Slither, Python3, ripgrep 등 전체 도구를 자동 감지/설치합니다.  
> `pnpm deps:all`은 위 시스템 의존성 설치 후 workspace 프론트 의존성(`pnpm install`)까지 연속 실행합니다.
> 설치 없이 확인만: `./install_all_deps.sh --check-only`

### 2) 전체 검증 실행
```bash
./run_all_tests.sh
# or
pnpm test:all
```
> `gates + lens + fork` 순서로 전체 검증을 실행합니다.  
> (`run_local_gates.sh --skip-fork` → `run_lens_tests.sh` → `run_fork_tests.sh`)

### 3) RPC 없는 환경 (포크 제외)
```bash
./run_all_tests.sh --skip-fork
```
> 네트워크 접근 없이 로컬 게이트 + Lens unit을 실행합니다. **신규 기여자 권장 시작점**.
> Lens suite까지 제외하려면 `./run_all_tests.sh --skip-fork --skip-lens`를 사용하세요.

### 4) Lens 테스트만 실행
```bash
./run_all_tests.sh --only lens --skip-fork
./scripts/runners/run_lens_tests.sh --skip-fork
```

### 5) 포크 테스트만 실행
```bash
./run_all_tests.sh --only fork
```

### 6) 로컬 배포/데모 (Anvil)
```bash
./deploy_local.sh
# or
pnpm deploy:local
```
> Core(Factory/Router/Pair) 배포 후 Lens(`NadSwapLensV1_1`)까지 같은 Anvil 체인에 배포하고,  
> 배포본 기준 Lens read-path 스모크 검증(`getPair`, `getPairsLength`, `getPairsPage`, `getPairView`)까지 자동 수행합니다.  
> 결과는 `envs/deployed.local.env` 한 파일에 저장되며, core + lens 주소와  
> `LENS_ADDRESS`, `LENS_FACTORY`, `LENS_ROUTER`, `LENS_CHAIN_ID`가 함께 기록됩니다.

### 7) 프론트엔드 실행 (`apps/nadswap`)
```bash
pnpm install
pnpm env:sync:nadswap
pnpm dev:nadswap
```
> `env:sync:nadswap`는 `envs/deployed.local.env`를 읽어  
> `apps/nadswap/.env.local`을 자동 생성합니다.

원커맨드(로컬 배포 + env 동기화 + 프론트 dev 실행):
```bash
pnpm dev:nadswap:local
```
> 실행 시 기존 `:8545` 프로세스를 정리 후 새 Anvil로 재배포하고, 종료(`Ctrl+C`)하면 Vite와 함께 해당 Anvil도 자동 종료됩니다.

### 포크 환경 설정

Monad testnet 포크 실행 시 환경 변수 템플릿을 사용합니다:

```bash
source envs/monad.testnet.env.sh
scripts/runners/run_fork_tests.sh -vv
```

> 상세 가이드: [docs/testing/FORK_TESTING_MONAD.md](docs/testing/FORK_TESTING_MONAD.md)

---

## 신뢰성 보증 체계

NadSwap은 코드만 테스트하지 않습니다. **코드-테스트-문서 정합성**까지 자동 검증하는 게이트 체계를 운영합니다.

| 게이트 | 역할 |
|--------|------|
| `check_traceability.py` | 요구사항 ID ↔ 테스트 ↔ 검증 명령 매핑을 자동 검증 |
| `check_docs_consistency.py` | Metrics / Source-of-truth / GENERATED 블록 동기화 검증 |
| `check_docs_symbol_refs.py` | 문서 내 계약 심볼·경로 참조의 유효성 검증 |
| `check_math_consistency.py` | 수학 공식 벡터 1,386 케이스 일관성 검증 |
| `check_storage_layout.py` | V2 원본 스토리지 슬롯 호환성 검증 |
| `check_slither_gate.py` | Slither 정적 분석 중간 이상 심각도 zero-tolerance |
| `check_migration_signoff.py` | Migration 체크리스트 13개 항목 완료 검증 |

> 즉, **"테스트가 통과했다"를 넘어서 "문서가 실제 구현을 정확히 설명하는지"까지** 게이트에 포함합니다.

---

## 운영 상 제약 / 비목표

- **FOT·리베이싱 미지원**: Router 경로에서 Base/Quote의 FOT(Fee-on-Transfer) 및 리베이싱 토큰은 지원 대상이 아닙니다.
- **운영 강제 정책**: Base는 온체인 allowlist가 없으므로 `pairAdmin`이 비FOT/비리베이싱 표준 ERC20만 상장해야 합니다.
- **포크 환경 의존성**: Fork 검증은 유효한 RPC/chainId/block 환경이 필수이며, 환경 누락 시 실패가 정상 동작입니다.
- **의도적 비호환**: Uniswap V2와 ABI 일부 호환을 유지하지만, 동작 레벨의 Breaking Changes가 존재합니다 (위 참고).

---

## 문제 해결 가이드

| 증상 | 원인/해결 |
|------|----------|
| `Could not resolve host` | 실행 환경 DNS에서 `testnet-rpc.monad.xyz` 해석 가능 여부 확인 |
| RPC 연결 실패 (`eth_chainId`, `eth_blockNumber`) | 네트워크 egress 정책/엔드포인트 접근 권한 확인 |
| chain id 불일치 | `MONAD_CHAIN_ID`와 RPC 응답 chain id를 맞춤 (기본 `10143`) |
| fork block 실패 | `MONAD_FORK_BLOCK`가 latest block을 초과하지 않는지 확인 |
| 환경 변수 누락 | `source envs/monad.testnet.env.sh` 후 다시 실행 |
| 사전 점검 | `python3 scripts/fork/preflight_monad.py`로 RPC/chain/block 유효성 확인 |

> 상세: [docs/testing/FORK_TESTING_MONAD.md](docs/testing/FORK_TESTING_MONAD.md)

---

## 재현성

- 로컬 게이트 실행 시 upstream 레퍼런스를 **pinned SHA**로 동기화합니다:
  - `v2-core`: `ee547b17853e71ed4e0101ccfd52e70d5acded58`
  - `v2-periphery`: `0335e8f7e1bd1e8d8329fd300aea2ef2f36dd19f`
- 검증 결과는 아래 스크립트로 **동일한 메트릭 수집 → 리포트 렌더링** 파이프라인을 거칩니다:
  ```bash
  python3 scripts/reports/collect_verification_metrics.py
  python3 scripts/reports/render_verification_reports.py
  ```
- 통합 실행: [scripts/runners/run_local_gates.sh](scripts/runners/run_local_gates.sh)

---

## 문서 인덱스

### 구현 명세
- 🇰🇷 [docs/NADSWAP_V2_IMPL_SPEC_KR.md](docs/NADSWAP_V2_IMPL_SPEC_KR.md)
- 🇺🇸 [docs/NADSWAP_V2_IMPL_SPEC_EN.md](docs/NADSWAP_V2_IMPL_SPEC_EN.md)

### 검증 · 리포트
- [docs/reports/NADSWAP_V2_VERIFICATION_REPORT.md](docs/reports/NADSWAP_V2_VERIFICATION_REPORT.md) — 검증 리포트
- [docs/reports/NADSWAP_V2_VERIFICATION_METRICS.json](docs/reports/NADSWAP_V2_VERIFICATION_METRICS.json) — 검증 메트릭 (기계판독)
- [docs/reports/NADSWAP_V2_SPEC_CONFORMANCE_REPORT.md](docs/reports/NADSWAP_V2_SPEC_CONFORMANCE_REPORT.md) — Spec 적합성 리포트
- [docs/reports/NADSWAP_V2_MIGRATION_SIGNOFF.md](docs/reports/NADSWAP_V2_MIGRATION_SIGNOFF.md) — Migration Signoff

### 추적성
- [docs/traceability/NADSWAP_V2_TRACE_MATRIX.md](docs/traceability/NADSWAP_V2_TRACE_MATRIX.md) — 요구사항 ↔ 테스트 매핑
- [docs/traceability/NADSWAP_V2_REQUIREMENTS.yaml](docs/traceability/NADSWAP_V2_REQUIREMENTS.yaml) — 요구사항 원본 (YAML)

### 테스트 가이드
- [docs/testing/FORK_TESTING_MONAD.md](docs/testing/FORK_TESTING_MONAD.md) — Monad 포크 테스트 가이드
- [docs/testing/VERIFICATION_GATES_KR.md](docs/testing/VERIFICATION_GATES_KR.md) — 검증 게이트 상세

### ABI 변경
- [docs/abi/NADSWAP_V2_ABI_DIFF.md](docs/abi/NADSWAP_V2_ABI_DIFF.md) — ABI 변경 비교

### Lens 문서
- [docs/lens/README.md](docs/lens/README.md) — NadSwap Lens 문서 인덱스
- [KR Guide Quickstart](docs/lens/NADSWAP_LENS_V1_1_GUIDE_KR.md#quickstart) — 로컬 배포 후 첫 호출 5~10분 가이드
- [KR Guide API Reference](docs/lens/NADSWAP_LENS_V1_1_GUIDE_KR.md#api-reference) — 함수별 입력/출력/실패 계약
- [EN Guide Quickstart](docs/lens/NADSWAP_LENS_V1_1_GUIDE_EN.md#quickstart) — First successful call in 5-10 minutes
- [EN Guide API Reference](docs/lens/NADSWAP_LENS_V1_1_GUIDE_EN.md#api-reference) — Function-level response/error contracts
