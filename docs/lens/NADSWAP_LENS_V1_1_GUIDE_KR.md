# NadSwap Lens V1.1 통합 가이드 (KR)

이 문서는 NadSwap Lens V1.1 문서를 한 파일에 통합한 운영 가이드입니다.
구성은 다음 3축을 중심으로 합니다.
- Quickstart: 5~10분 내 첫 성공 호출
- Cookbook: 실제 작업 단위 시나리오
- API Reference: 함수별 입력/출력/실패 계약

관련 문서:
- 배포 문서: [NADSWAP_LENS_V1_1_DEPLOYMENT.md](./NADSWAP_LENS_V1_1_DEPLOYMENT.md)
- 문서 인덱스: [README.md](./README.md)

## 0. Audience & Scope
### 대상 독자
- NadSwap Pair 데이터를 UI에 통합하는 프론트엔드 개발자
- 조회 파이프라인을 구성하는 백엔드/인덱서 개발자
- 정상/부분실패 상태를 검증하는 QA/운영 담당자

### 범위
- Lens V1.1의 read 함수만 다룹니다.
- 성공 응답, degraded 응답, revert/에러 동작을 함께 다룹니다.
- 실제 운영에서 필요한 페이지네이션/재시도 전략까지 포함합니다.

### 범위 제외
- write 트랜잭션 플로우
- GraphQL query/mutation 예시

### GraphQL 관련 안내
NadSwap Lens는 GraphQL API가 아니라 EVM 컨트랙트 read API입니다.
대신 아래 형식으로 동일 목적을 충족합니다.
- Solidity 함수 시그니처
- `cast call` 예시
- TypeScript 예시
- 오프셋 페이지네이션(`start`, `count`) 규칙

### 버전 기준
- 대상 컨트랙트: `lens/src/NadSwapLensV1_1.sol`
- 컨트랙트 버전: V1.1
- 컴파일러: `solc 0.8.25`
- EVM 타깃: `cancun`

<a id="quickstart"></a>
## 1. Quickstart (5~10분)
### 1.1 준비물
- `forge`, `cast` 설치
- `envs/local.env` 존재

### 1.2 로컬 코어 + Lens 배포
```bash
cd /Users/sunghoon-air/Desktop/projects.nosync/nad-swap
./scripts/deploy_local.sh
```

정상 완료 시 요약에 다음이 출력됩니다.
- `WETH`, `USDT`, `NAD`, `FACTORY`, `ROUTER`, `PAIR`
- `LENS`
- `Addresses saved to: envs/deployed.local.env`

### 1.3 배포 변수 로드
```bash
cd /Users/sunghoon-air/Desktop/projects.nosync/nad-swap
set -a
source envs/deployed.local.env
set +a
```

### 1.4 첫 호출 (`cast`)
```bash
cast call "$LENS_ADDRESS" "getPair(address,address)(address,bool)" "$USDT" "$NAD" --rpc-url "http://127.0.0.1:8545"
```

기대 성공 응답:
```text
(0xYourPairAddress, true)
```

### 1.5 첫 호출 (TypeScript, ethers)
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

### 1.6 즉시 점검 체크리스트
- `pair`가 `0x0000000000000000000000000000000000000000`가 아님
- `isValidPair == true`
- 반환 pair가 `envs/deployed.local.env`의 `PAIR_USDT_NAD`와 일치

<a id="cookbook"></a>
## 2. Cookbook (시나리오별)
## 2.A Pair 상세 화면 로딩 (`getPairView`)
### 목적
정적 메타데이터, 동적 회계 데이터, 유저 상태를 한 번에 조회합니다.

### 입력
- `pair`: 조회 대상 pair 주소
- `user`: 지갑 주소 또는 추적 대상 주소

### 호출 순서
1. `getPairView(pair, user)` 호출
2. `s.status`, `d.status`, `u.status` 확인
3. status가 `0`이면 정상 렌더, `2`면 경고와 함께 부분 렌더

### 성공 응답 패턴
- `s.status == 0`
- `d.status == 0`
- `u.status == 0` (또는 유저/allowance 조건에 따라 `2`)

### 실패/부분실패 케이스
- `s.status == 1` 또는 `d.status == 1` 또는 `u.status == 1`: invalid pair
- `d.status == 2`: dynamic 내부 `balanceOf` 읽기 degraded
- `u.status == 2`: zero user 또는 allowance 읽기 degraded

### 복구 방법
- status `1`: 해당 pair 화면을 invalid state로 전환
- status `2`: 부분 데이터 렌더 + 재시도 버튼 제공

## 2.B Pair 목록 페이지네이션 (`getPairsLength` -> `getPairsPage` -> 배치 상세)
### 목적
factory 열거가 가능한 경우 인덱서 없이 목록을 구성합니다.

### 입력
- `start`: 0-based offset
- `count`: 페이지 크기 (`<= 200`)

### 호출 순서
1. `getPairsLength()` 호출
2. `ok=false`면 인덱서 fallback 경로로 전환
3. `getPairsPage(start, count)` 호출
4. `ok=true`면 `getPairsStatic(page)`/`getPairsDynamic(page)` 호출

### 성공 응답 패턴
- `getPairsLength()` -> `(true, N)`
- `getPairsPage()` -> `(true, address[])`

### 실패/부분실패 케이스
- `getPairsLength()` -> `(false, 0)` (열거 미지원/실패)
- `getPairsPage()` -> `(false, [])` (`allPairs` index 호출 실패)
- `count > 200`이면 `COUNT_TOO_LARGE` revert
- batch 입력 길이 > 200이면 `BATCH_TOO_LARGE` revert

### 복구 방법
- 기본 페이지 크기를 25/50/100으로 제한
- `(false, ...)` 응답 시 인덱서 기반 목록 경로 사용
- oversize revert 발생 시 요청 크기 clamp 후 재시도

## 2.C 유저 포트폴리오 행 로딩 (`getUserState`)
### 목적
특정 pair 기준 유저 토큰/LP 잔고와 router allowance를 표시합니다.

### 입력
- `pair`
- `user`

### 호출 순서
1. `getUserState(pair, user)` 호출
2. `token0Balance`, `token1Balance`, `lpBalance` 사용
3. allowance 필드로 사용자 액션 가능 상태 표시

### 성공 응답 패턴
- `status == 0`

### 실패/부분실패 케이스
- `status == 1`: invalid pair
- `status == 2`: `user == address(0)` 또는 allowance read degraded

### 복구 방법
- 지갑 미연결 상태는 UI에서 먼저 차단하여 zero user 호출 방지
- allowance degraded 시 write CTA 비활성화 + 재조회 유도

## 2.D 장애 대응 플레이북
### 상황 1: `getPairsLength`/`getPairsPage`에서 `ok=false`
- 의미: factory 열거 경로 미지원 또는 런타임 실패
- 조치: 목록은 인덱서로 대체하고, per-pair 조회는 Lens 유지

### 상황 2: `status=2` 비율이 높음
- 의미: 비표준 토큰 동작 또는 일시적 RPC 불안정 가능성
- 조치: 부분 렌더 + 백오프 재시도 + degraded 비율 모니터링

### 상황 3: `COUNT_TOO_LARGE` / `BATCH_TOO_LARGE` revert
- 의미: 호출자가 하드 제한을 초과
- 조치: `count`, batch 길이를 `<= 200`으로 강제 clamp

<a id="api-reference"></a>
## 3. API Reference
### 3.1 컨트랙트 getter/상수
| 항목 | 타입 | 의미 |
|---|---|---|
| `factory()` | `address` | 배포 시 설정된 factory 주소 |
| `router()` | `address` | 배포 시 설정된 router 주소 (`0` 가능) |
| `LP_FEE_BPS()` | `uint16` | Lens 표시용 상수값 `20` |
| `MAX_BATCH()` | `uint256` | 하드 배치 제한값 `200` |

### 3.2 함수별 레퍼런스
#### `getPair`
| 항목 | 설명 |
|---|---|
| Signature | `getPair(address tokenA, address tokenB) returns (address pair, bool isValidPair)` |
| Parameters | `tokenA`, `tokenB` |
| Returns | `pair`: 매핑된 pair 주소 또는 zero, `isValidPair`: pair 존재 시 factory `isPair` 결과 |
| Success 조건 | 정상 리턴 |
| Failure mode | 상위 factory 호출이 revert될 수 있음 |
| Example response | `(0xPair, true)` / `(0xPair, false)` / `(0x000..., false)` |

#### `getPairStatic`
| 항목 | 설명 |
|---|---|
| Signature | `getPairStatic(address pair) returns (PairStatic s)` |
| Parameters | `pair` |
| Returns | `PairStatic` 전체 |
| Success 조건 | `factory.isPair(pair)==true`이고 하위 조회 성공 시 `s.status=0` |
| Failure mode | invalid pair는 revert 없이 `s.status=1` 반환. 하위 호출은 revert 전파 가능 |
| Example response | `s.status=0`이며 토큰/세율 메타데이터 채워짐 |

#### `getPairDynamic`
| 항목 | 설명 |
|---|---|
| Signature | `getPairDynamic(address pair) returns (PairDynamic d)` |
| Parameters | `pair` |
| Returns | `PairDynamic` 전체 |
| Success 조건 | 두 토큰 `balanceOf` read 성공 시 `d.status=0` |
| Failure mode | invalid pair면 `d.status=1`, 일부 balance read 실패면 `d.status=2` |
| Example response | `d.status=0` + reserve/raw/expected/dust/vault 필드 채워짐 |

#### `getUserState`
| 항목 | 설명 |
|---|---|
| Signature | `getUserState(address pair, address user) returns (UserState u)` |
| Parameters | `pair`, `user` |
| Returns | `UserState` 전체 |
| Success 조건 | pair 유효 + allowance read 성공(또는 router=0) 시 `u.status=0` |
| Failure mode | invalid pair면 `u.status=1`, zero user 또는 allowance read 실패면 `u.status=2` |
| Example response | `u.status=0` + balances/allowances 채워짐 |

#### `getPairView`
| 항목 | 설명 |
|---|---|
| Signature | `getPairView(address pair, address user) returns (PairStatic s, PairDynamic d, UserState u)` |
| Parameters | `pair`, `user` |
| Returns | static + dynamic + user 상태 통합 튜플 |
| Success 조건 | 튜플 정상 리턴 |
| Failure mode | 내부 `getPairStatic/getPairDynamic/getUserState` 동작 상속 |
| Example response | `s.status=0`, `d.status=0`, `u.status=0` |

#### `getPairsLength`
| 항목 | 설명 |
|---|---|
| Signature | `getPairsLength() returns (bool ok, uint256 len)` |
| Parameters | 없음 |
| Returns | `ok`: 열거 호출 성공 여부, `len`: `ok=true`일 때 전체 개수 |
| Success 조건 | `(true, N)` |
| Failure mode | `allPairsLength` 미지원/실패 시 `(false, 0)` |
| Example response | `(true, 123)` |

#### `getPairsPage`
| 항목 | 설명 |
|---|---|
| Signature | `getPairsPage(uint256 start, uint256 count) returns (bool ok, address[] pairs)` |
| Parameters | `start`, `count` (`count <= 200`) |
| Returns | `ok` + 페이지 배열 |
| Success 조건 | `ok=true`, `start>=len`이면 empty 배열 반환 |
| Failure mode | `count>200`이면 `COUNT_TOO_LARGE` revert, low-level `allPairs` 실패 시 `(false, [])` |
| Example response | `(true, [0xPair1, 0xPair2])` |

#### `getPairsStatic`
| 항목 | 설명 |
|---|---|
| Signature | `getPairsStatic(address[] pairs) returns (PairStatic[] out)` |
| Parameters | `pairs` 배열, 길이 `<= 200` |
| Returns | `PairStatic` 배열 |
| Success 조건 | 입력 길이만큼 반환 |
| Failure mode | 길이 초과 시 `BATCH_TOO_LARGE` revert |
| Example response | `[{status:0,...},{status:1,...}]` |

#### `getPairsDynamic`
| 항목 | 설명 |
|---|---|
| Signature | `getPairsDynamic(address[] pairs) returns (PairDynamic[] out)` |
| Parameters | `pairs` 배열, 길이 `<= 200` |
| Returns | `PairDynamic` 배열 |
| Success 조건 | 입력 길이만큼 반환 |
| Failure mode | 길이 초과 시 `BATCH_TOO_LARGE` revert |
| Example response | `[{status:0,...},{status:2,...}]` |

### 3.3 구조체 필드 사전
### `PairStatic`
| 필드 | 타입 | 의미 | 비고 |
|---|---|---|---|
| `status` | `uint8` | 0 OK, 1 INVALID_PAIR, 2 DEGRADED | 이 구조체에서는 보통 2를 사용하지 않음 |
| `pair` | `address` | 조회한 pair 주소 | 입력값 echo |
| `token0` | `address` | pair token0 | invalid pair 경로에서는 zero |
| `token1` | `address` | pair token1 | invalid pair 경로에서는 zero |
| `quoteToken` | `address` | pair의 quote token |  |
| `baseToken` | `address` | quote 반대편 토큰 | `isQuote0` 기반 계산 |
| `isQuote0` | `bool` | quote가 token0인지 여부 |  |
| `isQuoteSupported` | `bool` | factory quote token 지원 플래그 |  |
| `buyTaxBps` | `uint16` | 매수 세율 bps |  |
| `sellTaxBps` | `uint16` | 매도 세율 bps |  |
| `taxCollector` | `address` | 세금 수집 주소 |  |
| `lpFeeBps` | `uint16` | Lens 표시용 LP 수수료 상수 | 항상 20 |

### `PairDynamic`
| 필드 | 타입 | 의미 | 비고 |
|---|---|---|---|
| `status` | `uint8` | 0 OK, 1 INVALID_PAIR, 2 DEGRADED | 토큰 raw balance read 실패 시 2 |
| `pair` | `address` | 조회한 pair 주소 | 입력값 echo |
| `reserve0Eff` | `uint112` | reserve0 | pair `getReserves` 값 |
| `reserve1Eff` | `uint112` | reserve1 | pair `getReserves` 값 |
| `blockTimestampLast` | `uint32` | reserve timestamp | pair `getReserves` 값 |
| `raw0` | `uint256` | pair 내 token0 raw balance | read 실패 시 0 |
| `raw1` | `uint256` | pair 내 token1 raw balance | read 실패 시 0 |
| `vaultQuote` | `uint96` | 누적 quote tax vault | pair 값 |
| `rawQuote` | `uint256` | quote 관점 raw balance | raw0/raw1 기반 계산 |
| `rawBase` | `uint256` | base 관점 raw balance | raw0/raw1 기반 계산 |
| `expectedQuoteRaw` | `uint256` | 기대 quote raw = reserveQuote + vault |  |
| `expectedBaseRaw` | `uint256` | 기대 base raw = reserveBase |  |
| `dustQuote` | `uint256` | rawQuote 초과분 | 초과 없으면 0 |
| `dustBase` | `uint256` | rawBase 초과분 | 초과 없으면 0 |
| `vaultDrift` | `bool` | `rawQuote < vaultQuote` 여부 | quote-vault 불일치 위험 지표 |

### `UserState`
| 필드 | 타입 | 의미 | 비고 |
|---|---|---|---|
| `status` | `uint8` | 0 OK, 1 INVALID_PAIR, 2 DEGRADED | zero user/allowance degraded 시 2 |
| `pair` | `address` | 조회한 pair | 입력값 echo |
| `user` | `address` | 조회한 user | 입력값 echo |
| `token0` | `address` | pair token0 | early return 경로에서는 zero |
| `token1` | `address` | pair token1 | early return 경로에서는 zero |
| `token0Balance` | `uint256` | user token0 잔고 | read 실패 시 0 |
| `token1Balance` | `uint256` | user token1 잔고 | read 실패 시 0 |
| `lpBalance` | `uint256` | user LP 잔고 | read 실패 시 0 |
| `token0AllowanceToRouter` | `uint256` | token0->router allowance | router=0 또는 read 실패 시 0 |
| `token1AllowanceToRouter` | `uint256` | token1->router allowance | router=0 또는 read 실패 시 0 |
| `lpAllowanceToRouter` | `uint256` | LP->router allowance | router=0 또는 read 실패 시 0 |

<a id="failure-model"></a>
## 4. Error/Failure Model
### 4.1 명시적 revert 문자열
| Revert reason | 위치 | 트리거 |
|---|---|---|
| `ZERO_FACTORY` | constructor | factory를 zero로 배포 |
| `COUNT_TOO_LARGE` | `getPairsPage` | `count > MAX_BATCH(200)` |
| `BATCH_TOO_LARGE` | `getPairsStatic`, `getPairsDynamic` | 입력 길이 > 200 |

### 4.2 함수별 실패 방식 매트릭스
| 함수 | Revert | Soft fail (`ok=false`) | Status fail (`status=1/2`) |
|---|---|---|---|
| `getPair` | 상위 호출 revert 가능 | 없음 | `isValidPair` bool로 분기 |
| `getPairStatic` | 상위 호출 revert 가능 | 없음 | invalid pair 시 `status=1` |
| `getPairDynamic` | 상위 호출 revert 가능 | 없음 | invalid pair `1`, read degraded `2` |
| `getUserState` | 상위 호출 revert 가능 | 없음 | invalid pair `1`, zero user/allowance degraded `2` |
| `getPairView` | 내부 함수 동작 상속 | 없음 | 내부 함수 status 상속 |
| `getPairsLength` | 없음 (low-level 보호) | 있음 | 없음 |
| `getPairsPage` | `COUNT_TOO_LARGE`만 | 있음 | 없음 |
| `getPairsStatic` | `BATCH_TOO_LARGE` | 없음 | 요소별 `status=1` 가능 |
| `getPairsDynamic` | `BATCH_TOO_LARGE` | 없음 | 요소별 `status=1/2` 가능 |

### 4.3 클라이언트 처리 규칙
- Revert: 입력 제한/설정을 먼저 수정하고 재시도
- `ok=false`: 기능 미지원/런타임 실패로 간주하고 fallback 경로 전환
- `status=1`: 비즈니스 객체 invalid로 간주하고 해당 분기 중단
- `status=2`: 부분 데이터 모드로 렌더 + 재시도/경고 제공

## 5. Pagination & Throughput
### 5.1 페이지네이션 규칙
- cursor가 아니라 오프셋(`start`, `count`) 방식
- `count <= 200` 강제
- `start >= len`이면 `(true, [])` 반환

### 5.2 처리량 및 Rate limit
- Lens 컨트랙트 자체 rate limit은 없음
- 실제 제한은 RPC provider 정책에서 발생
- provider throttling을 피하려면 요청 크기와 동시성 제한 필요

### 5.3 권장 페이지 크기
- 인프라 안정: `count=100`
- 일반 기본값: `count=50`
- 불안정/public RPC: `count=25`

### 5.4 재시도/백오프 권장안
- transport/provider 일시 오류에만 재시도
- `COUNT_TOO_LARGE`, `BATCH_TOO_LARGE` 같은 결정적 revert는 재시도 금지
- 백오프 예시: `300ms -> 600ms -> 1200ms` + jitter ±20%
- 최대 재시도 횟수: UI 3회, 백엔드 잡 5회

## 6. Versioning & Compatibility
### 6.1 버전 라벨
- 컨트랙트: NadSwap Lens V1.1
- 문서: Lens Guide V1.1

### 6.2 호환성 정책
- 필드/함수 추가는 minor 문서 업데이트로 처리
- 기존 통합 로직에 영향 주는 동작 변경은 major 가이드 업데이트로 처리
- ABI break는 major 컨트랙트 버전 변경으로 취급

### 6.3 문서 동기화 정책
- KR/EN 섹션 번호와 표 구조를 동일하게 유지
- 배포 문서의 가이드 링크는 이 문서 앵커를 기준으로 유지

<a id="appendix"></a>
## 7. Appendix (cast/TS 예시 모음)
### 7.1 `cast call` 예시
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

### 7.2 TypeScript 헬퍼 스케치 (ethers)
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
