# NadSwap V2 Migration Signoff

| # | Item | Status | Notes |
|---|---|---|---|
| 1 | Factory admin model unified to pairAdmin (createPair expanded args, feeToSetter API removed) | Confirmed | Integrators must stop using `feeToSetter()/setFeeToSetter()` and legacy `createPair(address,address)`. |
| 2 | Router addLiquidity no auto-create | Confirmed | Pair must exist prior to add-liquidity flow. |
| 3 | Dual-output swap unsupported | Confirmed | Flash flows expecting dual-out must be refactored. |
| 4 | LP fee changed to 0.2% | Confirmed | Quote engines updated to `998/1000`. |
| 5 | Tax-aware quote math required | Confirmed | `getAmountsOut/In` patched for buy/sell tax semantics. |
| 6 | Swap event input semantics changed to effective input | Confirmed | Indexers should parse effective input model. |
| 7 | Reserves represent effective balances (vault excluded) | Confirmed | Analytics and reserve-derived metrics updated. |
| 8 | FOT-supporting router entrypoints revert | Confirmed | Keep ABI compatibility, runtime unsupported policy. |
| 9 | Pair address resolution via `factory.getPair` | Confirmed | Remove INIT_CODE_HASH derivation dependence. |
| 10 | Quote-out flash paths include sell tax | Confirmed | Strategy cost models must include quote output tax. |
| 11 | Sell exact-in quote uses 1 wei safe margin | Confirmed | Router quotes intentionally conservative by <=1 wei. |
| 12 | claimQuoteFees may absorb quote dust on reserve sync | Confirmed | Accounting/reporting should treat this as expected behavior. |
| 13 | Storage slot compatibility for V2 fields is mandatory | Confirmed | `check_storage_layout.py` gate active in CI. |
