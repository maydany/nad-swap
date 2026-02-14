# NadSwap V2 Monad Fork Testing (Deploy-Mode)

## 목표
- 로컬 게이트(`core/periphery/fuzz/invariant`)와 별도로 Monad testnet fork에서 fork 전용 통합 검증을 반복 가능하게 운영한다.
- 운영 기본 정책은 manual-first(`workflow_dispatch`)다.

## 실행 모드

### Mode A — Runner (`scripts/runners/run_fork_tests.sh`)
- 권장 모드. preflight + core/periphery/fuzz-lite 실행 + 로그 정리를 한 번에 수행한다.
- Runner가 `MONAD_FORK_ENABLED=1`을 자동 export 한다.

### Mode B — Direct `forge test`
- 세부 디버깅/부분 실행용 모드.
- 테스트에서 `onlyFork` 가드가 있으므로 `MONAD_FORK_ENABLED=1`을 직접 export 해야 한다.

## 환경 변수 매트릭스

| 변수 | Mode A (Runner) | Mode B (Direct forge) |
|---|---|---|
| `MONAD_FORK_ENABLED` | Auto-exported by runner | Required (`1`) |
| `MONAD_RPC_URL` | Required | Required |
| `MONAD_CHAIN_ID` | Required (default `10143`) | Required (default `10143`) |
| `MONAD_FORK_BLOCK` | Required (`0` = latest) | Required (`0` = latest) |
| `MONAD_FORK_FUZZ_RUNS` | Required (default `64`) | Optional (used when running fuzz-lite) |

참고: 현재 `protocol/test/fork`는 fork 위에 mock quote/base 토큰을 직접 배포하므로 token/whale/liquidity 관련 env는 필요하지 않다.

## Mode A 로컬 실행 (권장)
```bash
scripts/runners/run_fork_tests.sh \
  --rpc "https://testnet-rpc.monad.xyz" \
  --chain-id 10143 \
  --block 12700000 \
  --fuzz-runs 64 \
  -vv
```

latest 블록을 사용하려면:
```bash
scripts/runners/run_fork_tests.sh \
  --rpc "https://testnet-rpc.monad.xyz" \
  --chain-id 10143 \
  --latest \
  --fuzz-runs 64 \
  -vv
```

## Mode B 로컬 실행 (직접 forge)
```bash
export MONAD_FORK_ENABLED=1
export MONAD_RPC_URL="https://testnet-rpc.monad.xyz"
export MONAD_CHAIN_ID=10143
export MONAD_FORK_BLOCK=12700000
export MONAD_FORK_FUZZ_RUNS=64

python3 scripts/fork/preflight_monad.py

cd protocol
forge test --match-path "test/fork/core/**/*.t.sol" --fork-url "$MONAD_RPC_URL" --fork-block-number "$MONAD_FORK_BLOCK" -vv
forge test --match-path "test/fork/periphery/**/*.t.sol" --fork-url "$MONAD_RPC_URL" --fork-block-number "$MONAD_FORK_BLOCK" -vv
forge test --match-contract ForkFuzzLiteTest --fork-url "$MONAD_RPC_URL" --fork-block-number "$MONAD_FORK_BLOCK" --fuzz-runs "$MONAD_FORK_FUZZ_RUNS" -vv
```

## 수동 GitHub Actions 실행
- Workflow: `.github/workflows/fork-manual.yml`
- Trigger: `workflow_dispatch`
- 입력 항목:
  - RPC URL / chain id / fork block
  - fuzz runs

## 테스트 레이어 구조
- `protocol/test/fork/core`
  - swap / lifecycle / claim / factory policy
- `protocol/test/fork/periphery`
  - router parity / policy guards
- `protocol/test/fork/ForkFuzzLite.t.sol`
  - 제한 fuzz

## Troubleshooting
1. DNS 실패 (`Could not resolve host`)
- 실행 환경 DNS에서 `testnet-rpc.monad.xyz` 해석 가능 여부 확인.

2. RPC 연결 실패 (`eth_chainId`/`eth_blockNumber`)
- 네트워크 egress 정책 및 RPC endpoint 접근 권한 확인.

3. chain id 불일치
- `MONAD_CHAIN_ID` 값이 RPC의 `eth_chainId`와 일치하는지 확인.

4. fork block 실패
- `MONAD_FORK_BLOCK` 값이 latest block보다 크지 않은지 확인.
