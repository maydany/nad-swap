# NadSwap V2 ABI Diff

## Factory

### Breaking changes
- `createPair(address,address)` removed.
- New signature:
  - `createPair(address tokenA, address tokenB, uint16 buyTaxBps, uint16 sellTaxBps, address feeCollector)`
- Access control: `createPair` is `pairAdmin`-only.
- Constructor changed:
  - `constructor(address pairAdmin)`
- Removed factory admin API:
  - `feeToSetter()`
  - `setFeeToSetter(address)`
- Removed base allowlist API:
  - `isBaseTokenSupported(address)`
  - `setBaseTokenSupported(address,bool)`
- Access control changed:
  - `setQuoteToken(address,bool)` is `pairAdmin`-only
  - `setFeeTo(address)` is `pairAdmin`-only
- Behavioral policy change:
  - `BASE_NOT_SUPPORTED` guard path removed from Factory `createPair` and Router support guard.

### Added getters / methods
- `pairAdmin() -> address`
- `isQuoteToken(address) -> bool`
- `isPair(address) -> bool`
- `setQuoteToken(address,bool)`
- `setTaxConfig(address pair,uint16 buyTaxBps,uint16 sellTaxBps,address feeCollector)`

## Pair

### Added public state getters
- `quoteToken() -> address`
- `buyTaxBps() -> uint16`
- `sellTaxBps() -> uint16`
- `feeCollector() -> address`
- `accumulatedQuoteFees() -> uint96`

### Added methods
- `initialize(address token0,address token1,address quoteToken,uint16 buyTaxBps,uint16 sellTaxBps,address feeCollector)`
- `setTaxConfig(uint16 buyTaxBps,uint16 sellTaxBps,address feeCollector)`
- `claimQuoteFees(address to)`

### Behavior differences
- `swap` enforces single-sided output (`SINGLE_SIDE_ONLY`).
- `Swap` event input values are effective-input based after vault application.

### Added events
- `TaxConfigUpdated(uint16,uint16,address)`
- `QuoteFeesAccrued(uint256,uint256,uint256)`
- `QuoteFeesClaimed(address,uint256)`

## Router

### Preserved signatures with runtime policy changes
- FOT-supporting swap/remove methods are preserved in ABI, but always revert with `FOT_NOT_SUPPORTED`.

### Behavioral patch
- `_addLiquidity` no longer auto-creates pairs.
- If pair does not exist, router reverts with `PAIR_NOT_CREATED`.

## Library

### Math changes
- LP fee constants updated from `997/1000` to `998/1000`.
- `pairFor` resolves via `factory.getPair` (no INIT_CODE_HASH derivation).
- `getAmountsOut/In` now include tax-aware buy/sell direction logic.
