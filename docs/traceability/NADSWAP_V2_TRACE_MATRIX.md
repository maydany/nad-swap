# NadSwap V2 Traceability Matrix

| ID | Spec | Code | Tests | Verification Command | Status |
|---|---|---|---|---|---|
| PAIR-001 | 4. initialize | `protocol/src/core/NadSwapV2Pair.sol` | `test_initialize_nonFactory_revert,test_initialize_reentryBlocked,test_initialize_invalidQuote,test_initialize_taxTooHigh_revert` | `FOUNDRY_OFFLINE=true forge test --match-contract FactoryAdminExtTest` | Implemented |
| PAIR-002 | 9. setTaxConfig | `protocol/src/core/NadSwapV2Pair.sol` | `test_setTaxConfig_maxTax_revert,test_setTaxConfig_zeroTaxCollector,test_setTaxConfig_nonFactory_revert` | `FOUNDRY_OFFLINE=true forge test --match-contract FactoryAdminExtTest` | Implemented |
| PAIR-003 | 6. swap single-side | `protocol/src/core/NadSwapV2Pair.sol` | `test_singleSideOnly_revert` | `FOUNDRY_OFFLINE=true forge test --match-test test_singleSideOnly_revert` | Implemented |
| PAIR-004 | 6. swap invalid to | `protocol/src/core/NadSwapV2Pair.sol` | `test_swap_invalidTo_revert` | `FOUNDRY_OFFLINE=true forge test --match-test test_swap_invalidTo_revert` | Implemented |
| PAIR-005 | 6. sell reverse ceil | `protocol/src/core/NadSwapV2Pair.sol` | `test_sell_reverseMath_ceilGross` | `FOUNDRY_OFFLINE=true forge test --match-test test_sell_reverseMath_ceilGross` | Implemented |
| PAIR-006 | 6. buy pre-deduction | `protocol/src/core/NadSwapV2Pair.sol` | `test_buy_preDeduction_taxIn` | `FOUNDRY_OFFLINE=true forge test --match-test test_buy_preDeduction_taxIn` | Implemented |
| PAIR-007 | 6. non-zero input | `protocol/src/core/NadSwapV2Pair.sol` | `test_swap_zeroInput_revert` | `FOUNDRY_OFFLINE=true forge test --match-test test_swap_zeroInput_revert` | Implemented |
| PAIR-008 | 8. claim access + recipient | `protocol/src/core/NadSwapV2Pair.sol` | `test_claim_nonTaxCollector_revert,test_claim_zeroAddress_revert` | `FOUNDRY_OFFLINE=true forge test --match-contract PairSwapTest` | Implemented |
| PAIR-009 | 8. claim vault reset | `protocol/src/core/NadSwapV2Pair.sol` | `test_claim_vaultReset_reserveSync` | `FOUNDRY_OFFLINE=true forge test --match-test test_claim_vaultReset_reserveSync` | Implemented |
| PAIR-010 | 8. claim reserve unchanged + dust semantics | `protocol/src/core/NadSwapV2Pair.sol` | `test_claim_vaultReset_reserveSync,test_claim_doesNotAbsorbDust` | `FOUNDRY_OFFLINE=true forge test --match-test test_claim_doesNotAbsorbDust` | Implemented |
| FACT-001 | 10. createPair access control | `protocol/src/core/NadSwapV2Factory.sol` | `test_createPair_onlyPairAdmin` | `FOUNDRY_OFFLINE=true forge test --match-test test_createPair_onlyPairAdmin` | Implemented |
| FACT-002 | 10. BOTH_QUOTE | `protocol/src/core/NadSwapV2Factory.sol` | `test_createPair_bothQuote_revert` | `FOUNDRY_OFFLINE=true forge test --match-test test_createPair_bothQuote_revert` | Implemented |
| FACT-003 | 10. QUOTE_REQUIRED | `protocol/src/core/NadSwapV2Factory.sol` | `test_createPair_noQuote_revert` | `FOUNDRY_OFFLINE=true forge test --match-test test_createPair_noQuote_revert` | Implemented |
| FACT-004 | 10. base allowlist removed | `protocol/src/core/NadSwapV2Factory.sol` | `test_createPair_unlistedBase_success` | `FOUNDRY_OFFLINE=true forge test --match-test test_createPair_unlistedBase_success` | Implemented |
| FACT-005 | 10. duplicate pair | `protocol/src/core/NadSwapV2Factory.sol` | `test_createPair_duplicate_revert` | `FOUNDRY_OFFLINE=true forge test --match-test test_createPair_duplicate_revert` | Implemented |
| FACT-006 | 10. constructor guard | `protocol/src/core/NadSwapV2Factory.sol` | `test_constructor_zeroAddress_revert` | `FOUNDRY_OFFLINE=true forge test --match-test test_constructor_zeroAddress_revert` | Implemented |
| FACT-007 | 10. setQuoteToken guard | `protocol/src/core/NadSwapV2Factory.sol` | `test_setQuoteToken_zeroAddr_revert` | `FOUNDRY_OFFLINE=true forge test --match-test test_setQuoteToken_zeroAddr_revert` | Implemented |
| FACT-008 | 10. base allowlist API removed | `protocol/src/core/NadSwapV2Factory.sol` | `test_baseAllowlistApi_setter_removed,test_baseAllowlistApi_getter_removed` | `FOUNDRY_OFFLINE=true forge test --match-contract FactoryAdminExtTest` | Implemented |
| FACT-009 | 10. setFeeTo access | `protocol/src/core/NadSwapV2Factory.sol` | `test_setFeeTo_onlyPairAdmin_revert,test_setFeeTo_pairAdmin_success` | `FOUNDRY_OFFLINE=true forge test --match-contract FactoryTest` | Implemented |
| LIB-001 | 11. 998/1000 | `protocol/src/periphery/libraries/NadSwapV2Library.sol` | `test_library_lpFee_998` | `FOUNDRY_OFFLINE=true forge test --match-test test_library_lpFee_998` | Implemented |
| LIB-002 | 11. pairFor mapping lookup | `protocol/src/periphery/libraries/NadSwapV2Library.sol` | `test_pairFor_usesFactoryGetPair` | `FOUNDRY_OFFLINE=true forge test --match-test test_pairFor_usesFactoryGetPair` | Implemented |
| LIB-003 | 11. sell exact-in safe margin | `protocol/src/periphery/libraries/NadSwapV2Library.sol` | `test_sellExactIn_safeMargin_avoidsLiquidityEdge` | `FOUNDRY_OFFLINE=true forge test --match-test test_sellExactIn_safeMargin_avoidsLiquidityEdge` | Implemented |
| ROUT-001 | 10. remove auto pair creation | `protocol/src/periphery/NadSwapV2Router02.sol` | `test_router_noPairRevert` | `FOUNDRY_OFFLINE=true forge test --match-test test_router_noPairRevert` | Implemented |
| ROUT-002 | 10. FOT hard revert | `protocol/src/periphery/NadSwapV2Router02.sol` | `test_router_supportingFOT_notSupported,test_router_supportingFOT_notSupported_exactETHForTokens,test_router_supportingFOT_notSupported_exactTokensForETH,test_router_supportingFOT_notSupported_removeLiquidityETH,test_router_supportingFOT_notSupported_removeLiquidityETHWithPermit` | `FOUNDRY_OFFLINE=true forge test --match-contract RouterLibraryTest` | Implemented |
| REG-001 | 16. tax=0 regression | `protocol/test/core/Regression.t.sol` | `test_regression_taxZero_swapMatchesFeeOnlyMath` | `FOUNDRY_OFFLINE=true forge test --match-test test_regression_taxZero_swapMatchesFeeOnlyMath` | Implemented |
| FUZ-001 | 16. fuzz | `protocol/test/core/FuzzInvariant.t.sol` | `testFuzz_buyTax_floor_matchesPair` | `FOUNDRY_OFFLINE=true forge test --match-test testFuzz_buyTax_floor_matchesPair` | Implemented |
| INV-001 | 16. invariant | `protocol/test/core/FuzzInvariant.t.sol` | `testInvariant_rawQuote_equals_reservePlusVault_afterSync` | `FOUNDRY_OFFLINE=true forge test --match-test testInvariant_rawQuote_equals_reservePlusVault_afterSync` | Implemented |
| INV-002 | 16. stateful invariant quote accounting | `protocol/test/invariant/StatefulPairInvariant.t.sol` | `invariant_raw_quote_eq_reserve_plus_vault_or_dust` | `FOUNDRY_OFFLINE=true forge test --match-path "test/invariant/**" --match-test invariant_raw_quote_eq_reserve_plus_vault_or_dust` | Implemented |
| INV-003 | 16. stateful invariant vault monotonic | `protocol/test/invariant/StatefulPairInvariant.t.sol` | `invariant_vault_monotonic_except_claim` | `FOUNDRY_OFFLINE=true forge test --match-path "test/invariant/**" --match-test invariant_vault_monotonic_except_claim` | Implemented |
| INV-004 | 16. stateful invariant LP supply/reserves | `protocol/test/invariant/StatefulPairInvariant.t.sol` | `invariant_totalSupply_implies_positive_reserves` | `FOUNDRY_OFFLINE=true forge test --match-path "test/invariant/**" --match-test invariant_totalSupply_implies_positive_reserves` | Implemented |
| INV-005 | 16. stateful invariant factory mapping | `protocol/test/invariant/StatefulPairInvariant.t.sol` | `invariant_factory_pair_mapping_consistency` | `FOUNDRY_OFFLINE=true forge test --match-path "test/invariant/**" --match-test invariant_factory_pair_mapping_consistency` | Implemented |
| INV-006 | 16. stateful invariant quote-exec drift | `protocol/test/invariant/StatefulPairInvariant.t.sol` | `invariant_router_quote_exec_error_le_1wei_executable_domain` | `FOUNDRY_OFFLINE=true forge test --match-path "test/invariant/**" --match-test invariant_router_quote_exec_error_le_1wei_executable_domain` | Implemented |
| SEC-001 | 4. storage layout gate | `scripts/gates/check_storage_layout.py` | `N/A` | `python3 scripts/gates/check_storage_layout.py` | Implemented |
| SEC-002 | 5/6/11 math parity gate | `scripts/gates/check_math_consistency.py` | `N/A` | `python3 scripts/gates/check_math_consistency.py` | Implemented |
| SEC-003 | 16. static analysis gate | `scripts/gates/check_slither_gate.py` | `N/A` | `python3 scripts/gates/check_slither_gate.py` | Implemented |
## Spec Section 16 Test Coverage

- Coverage target: `88` spec `test_*` names + `5` spec `invariant_*` names
- Current status: `93/93` mapped

| Test Name | Code File | Verification Command | Status |
|---|---|---|---|
| `test_sell_exactIn_grossOut_diverge` | `protocol/test/periphery/RouterQuoteParity.t.sol` | `FOUNDRY_OFFLINE=true forge test --match-test test_sell_exactIn_grossOut_diverge` | Implemented |
| `test_sell_reverseMath_ceilGross` | `protocol/test/core/PairSwap.t.sol` | `FOUNDRY_OFFLINE=true forge test --match-test test_sell_reverseMath_ceilGross` | Implemented |
| `test_buy_preDeduction_taxIn` | `protocol/test/core/PairSwap.t.sol` | `FOUNDRY_OFFLINE=true forge test --match-test test_buy_preDeduction_taxIn` | Implemented |
| `test_directCall_cannotBypassTax` | `protocol/test/core/PairSwapGuards.t.sol` | `FOUNDRY_OFFLINE=true forge test --match-test test_directCall_cannotBypassTax` | Implemented |
| `test_quoteFlash_sameToken_sellTax_applies` | `protocol/test/core/PairFlashQuote.t.sol` | `FOUNDRY_OFFLINE=true forge test --match-test test_quoteFlash_sameToken_sellTax_applies` | Implemented |
| `test_quoteFlash_sameToken_noBypass_coreTax` | `protocol/test/core/PairFlashQuote.t.sol` | `FOUNDRY_OFFLINE=true forge test --match-test test_quoteFlash_sameToken_noBypass_coreTax` | Implemented |
| `test_quoteFlash_sameToken_buyTax_notApplied_when_noBaseOut` | `protocol/test/core/PairFlashQuote.t.sol` | `FOUNDRY_OFFLINE=true forge test --match-test test_quoteFlash_sameToken_buyTax_notApplied_when_noBaseOut` | Implemented |
| `test_quoteFlash_sameToken_kInvariant_holds_after_tax` | `protocol/test/core/PairFlashQuote.t.sol` | `FOUNDRY_OFFLINE=true forge test --match-test test_quoteFlash_sameToken_kInvariant_holds_after_tax` | Implemented |
| `test_swapEvent_usesEffIn` | `protocol/test/core/PairSwapGuards.t.sol` | `FOUNDRY_OFFLINE=true forge test --match-test test_swapEvent_usesEffIn` | Implemented |
| `test_swap_invalidTo_revert` | `protocol/test/core/PairSwap.t.sol` | `FOUNDRY_OFFLINE=true forge test --match-test test_swap_invalidTo_revert` | Implemented |
| `test_singleSideOnly_revert` | `protocol/test/core/PairSwap.t.sol` | `FOUNDRY_OFFLINE=true forge test --match-test test_singleSideOnly_revert` | Implemented |
| `test_singleSide_swapExactTokens` | `protocol/test/core/PairSwapGuards.t.sol` | `FOUNDRY_OFFLINE=true forge test --match-test test_singleSide_swapExactTokens` | Implemented |
| `test_singleSide_swapForExactTokens` | `protocol/test/core/PairSwapGuards.t.sol` | `FOUNDRY_OFFLINE=true forge test --match-test test_singleSide_swapForExactTokens` | Implemented |
| `test_singleSide_flashCallback` | `protocol/test/core/PairSwapGuards.t.sol` | `FOUNDRY_OFFLINE=true forge test --match-test test_singleSide_flashCallback` | Implemented |
| `test_vaultOverflow_revert` | `protocol/test/core/PairSwapGuards.t.sol` | `FOUNDRY_OFFLINE=true forge test --match-test test_vaultOverflow_revert` | Implemented |
| `test_sell_exactIn_liquidityEdge` | `protocol/test/core/PairSwapGuards.t.sol` | `FOUNDRY_OFFLINE=true forge test --match-test test_sell_exactIn_liquidityEdge` | Implemented |
| `test_swap_zeroInput_revert` | `protocol/test/core/PairSwap.t.sol` | `FOUNDRY_OFFLINE=true forge test --match-test test_swap_zeroInput_revert` | Implemented |
| `test_swap_insufficientLiquidity` | `protocol/test/core/PairSwapGuards.t.sol` | `FOUNDRY_OFFLINE=true forge test --match-test test_swap_insufficientLiquidity` | Implemented |
| `test_swap_bothZeroOut_revert` | `protocol/test/core/PairSwap.t.sol` | `FOUNDRY_OFFLINE=true forge test --match-test test_swap_bothZeroOut_revert` | Implemented |
| `test_sell_grossOut_exceedsReserve` | `protocol/test/core/PairSwapGuards.t.sol` | `FOUNDRY_OFFLINE=true forge test --match-test test_sell_grossOut_exceedsReserve` | Implemented |
| `test_swap_vaultDrift_oldVault_revert` | `protocol/test/core/PairSwapGuards.t.sol` | `FOUNDRY_OFFLINE=true forge test --match-test test_swap_vaultDrift_oldVault_revert` | Implemented |
| `test_swap_vaultDrift_newVault_revert` | `protocol/test/core/PairSwapGuards.t.sol` | `FOUNDRY_OFFLINE=true forge test --match-test test_swap_vaultDrift_newVault_revert` | Implemented |
| `test_buy_sell_sequential` | `protocol/test/core/PairSwapGuards.t.sol` | `FOUNDRY_OFFLINE=true forge test --match-test test_buy_sell_sequential` | Implemented |
| `test_kInvariant_afterTaxedSwap` | `protocol/test/core/PairSwapGuards.t.sol` | `FOUNDRY_OFFLINE=true forge test --match-test test_kInvariant_afterTaxedSwap` | Implemented |
| `test_mint_excludesVault` | `protocol/test/core/PairLifecycle.t.sol` | `FOUNDRY_OFFLINE=true forge test --match-test test_mint_excludesVault` | Implemented |
| `test_burn_excludesVault` | `protocol/test/core/PairLifecycle.t.sol` | `FOUNDRY_OFFLINE=true forge test --match-test test_burn_excludesVault` | Implemented |
| `test_mint_afterSwap_vaultIntact` | `protocol/test/core/PairLifecycle.t.sol` | `FOUNDRY_OFFLINE=true forge test --match-test test_mint_afterSwap_vaultIntact` | Implemented |
| `test_burn_afterSwap_vaultIntact` | `protocol/test/core/PairLifecycle.t.sol` | `FOUNDRY_OFFLINE=true forge test --match-test test_burn_afterSwap_vaultIntact` | Implemented |
| `test_skim_underflow_safe` | `protocol/test/core/PairLifecycle.t.sol` | `FOUNDRY_OFFLINE=true forge test --match-test test_skim_underflow_safe` | Implemented |
| `test_skim_excessDust_transfer` | `protocol/test/core/PairLifecycle.t.sol` | `FOUNDRY_OFFLINE=true forge test --match-test test_skim_excessDust_transfer` | Implemented |
| `test_sync_withVault_usesEffective` | `protocol/test/core/PairLifecycle.t.sol` | `FOUNDRY_OFFLINE=true forge test --match-test test_sync_withVault_usesEffective` | Implemented |
| `test_sync_afterClaim` | `protocol/test/core/PairLifecycle.t.sol` | `FOUNDRY_OFFLINE=true forge test --match-test test_sync_afterClaim` | Implemented |
| `test_mint_vaultDrift_revert` | `protocol/test/core/PairLifecycle.t.sol` | `FOUNDRY_OFFLINE=true forge test --match-test test_mint_vaultDrift_revert` | Implemented |
| `test_burn_vaultDrift_revert` | `protocol/test/core/PairLifecycle.t.sol` | `FOUNDRY_OFFLINE=true forge test --match-test test_burn_vaultDrift_revert` | Implemented |
| `test_sync_vaultDrift_revert` | `protocol/test/core/PairLifecycle.t.sol` | `FOUNDRY_OFFLINE=true forge test --match-test test_sync_vaultDrift_revert` | Implemented |
| `test_claim_vaultReset_reserveSync` | `protocol/test/core/PairSwap.t.sol` | `FOUNDRY_OFFLINE=true forge test --match-test test_claim_vaultReset_reserveSync` | Implemented |
| `test_claim_doesNotAbsorbDust` | `protocol/test/core/ClaimTaxAdvanced.t.sol` | `FOUNDRY_OFFLINE=true forge test --match-test test_claim_doesNotAbsorbDust` | Implemented |
| `test_claim_selfTransfer_revert` | `protocol/test/core/ClaimTaxAdvanced.t.sol` | `FOUNDRY_OFFLINE=true forge test --match-test test_claim_selfTransfer_revert` | Implemented |
| `test_claim_zeroAddress_revert` | `protocol/test/core/PairSwap.t.sol` | `FOUNDRY_OFFLINE=true forge test --match-test test_claim_zeroAddress_revert` | Implemented |
| `test_claim_noTax_revert` | `protocol/test/core/PairSwap.t.sol` | `FOUNDRY_OFFLINE=true forge test --match-test test_claim_noTax_revert` | Implemented |
| `test_claim_nonTaxCollector_revert` | `protocol/test/core/PairSwap.t.sol` | `FOUNDRY_OFFLINE=true forge test --match-test test_claim_nonTaxCollector_revert` | Implemented |
| `test_claim_reentrancy_blocked` | `protocol/test/core/ClaimTaxAdvanced.t.sol` | `FOUNDRY_OFFLINE=true forge test --match-test test_claim_reentrancy_blocked` | Implemented |
| `test_claim_vaultDrift_revert` | `protocol/test/core/ClaimTaxAdvanced.t.sol` | `FOUNDRY_OFFLINE=true forge test --match-test test_claim_vaultDrift_revert` | Implemented |
| `test_setTaxConfig_alwaysMutable` | `protocol/test/core/FactoryAdminExt.t.sol` | `FOUNDRY_OFFLINE=true forge test --match-test test_setTaxConfig_alwaysMutable` | Implemented |
| `test_setTaxConfig_zeroTaxCollector` | `protocol/test/core/FactoryAdminExt.t.sol` | `FOUNDRY_OFFLINE=true forge test --match-test test_setTaxConfig_zeroTaxCollector` | Implemented |
| `test_setTaxConfig_maxTax_revert` | `protocol/test/core/Factory.t.sol` | `FOUNDRY_OFFLINE=true forge test --match-test test_setTaxConfig_maxTax_revert` | Implemented |
| `test_setTaxConfig_sellTax100pct_revert` | `protocol/test/core/FactoryAdminExt.t.sol` | `FOUNDRY_OFFLINE=true forge test --match-test test_setTaxConfig_sellTax100pct_revert` | Implemented |
| `test_setTaxConfig_nonFactory_revert` | `protocol/test/core/FactoryAdminExt.t.sol` | `FOUNDRY_OFFLINE=true forge test --match-test test_setTaxConfig_nonFactory_revert` | Implemented |
| `test_taxChange_raceCond_slippage` | `protocol/test/periphery/RouterQuoteParity.t.sol` | `FOUNDRY_OFFLINE=true forge test --match-test test_taxChange_raceCond_slippage` | Implemented |
| `test_createPair_onlyPairAdmin` | `protocol/test/core/Factory.t.sol` | `FOUNDRY_OFFLINE=true forge test --match-test test_createPair_onlyPairAdmin` | Implemented |
| `test_createPair_frontRunBlocked` | `protocol/test/core/FactoryAdminExt.t.sol` | `FOUNDRY_OFFLINE=true forge test --match-test test_createPair_frontRunBlocked` | Implemented |
| `test_createPair_bothQuote_revert` | `protocol/test/core/Factory.t.sol` | `FOUNDRY_OFFLINE=true forge test --match-test test_createPair_bothQuote_revert` | Implemented |
| `test_createPair_noQuote_revert` | `protocol/test/core/Factory.t.sol` | `FOUNDRY_OFFLINE=true forge test --match-test test_createPair_noQuote_revert` | Implemented |
| `test_createPair_unlistedBase_success` | `protocol/test/core/Factory.t.sol` | `FOUNDRY_OFFLINE=true forge test --match-test test_createPair_unlistedBase_success` | Implemented |
| `test_createPair_duplicate_revert` | `protocol/test/core/Factory.t.sol` | `FOUNDRY_OFFLINE=true forge test --match-test test_createPair_duplicate_revert` | Implemented |
| `test_factory_invalidPair_revert` | `protocol/test/core/FactoryAdminExt.t.sol` | `FOUNDRY_OFFLINE=true forge test --match-test test_factory_invalidPair_revert` | Implemented |
| `test_setQuoteToken_zeroAddr_revert` | `protocol/test/core/Factory.t.sol` | `FOUNDRY_OFFLINE=true forge test --match-test test_setQuoteToken_zeroAddr_revert` | Implemented |
| `test_setQuoteToken_nonPairAdmin_revert` | `protocol/test/core/FactoryAdminExt.t.sol` | `FOUNDRY_OFFLINE=true forge test --match-test test_setQuoteToken_nonPairAdmin_revert` | Implemented |
| `test_baseAllowlistApi_setter_removed` | `protocol/test/core/FactoryAdminExt.t.sol` | `FOUNDRY_OFFLINE=true forge test --match-test test_baseAllowlistApi_setter_removed` | Implemented |
| `test_baseAllowlistApi_getter_removed` | `protocol/test/core/FactoryAdminExt.t.sol` | `FOUNDRY_OFFLINE=true forge test --match-test test_baseAllowlistApi_getter_removed` | Implemented |
| `test_setFeeTo_onlyPairAdmin_revert` | `protocol/test/core/Factory.t.sol` | `FOUNDRY_OFFLINE=true forge test --match-test test_setFeeTo_onlyPairAdmin_revert` | Implemented |
| `test_setFeeTo_pairAdmin_success` | `protocol/test/core/Factory.t.sol` | `FOUNDRY_OFFLINE=true forge test --match-test test_setFeeTo_pairAdmin_success` | Implemented |
| `test_constructor_zeroAddress_revert` | `protocol/test/core/Factory.t.sol` | `FOUNDRY_OFFLINE=true forge test --match-test test_constructor_zeroAddress_revert` | Implemented |
| `test_initialize_reentryBlocked` | `protocol/test/core/FactoryAdminExt.t.sol` | `FOUNDRY_OFFLINE=true forge test --match-test test_initialize_reentryBlocked` | Implemented |
| `test_initialize_zeroTaxCollector` | `protocol/test/core/FactoryAdminExt.t.sol` | `FOUNDRY_OFFLINE=true forge test --match-test test_initialize_zeroTaxCollector` | Implemented |
| `test_initialize_invalidQuote` | `protocol/test/core/FactoryAdminExt.t.sol` | `FOUNDRY_OFFLINE=true forge test --match-test test_initialize_invalidQuote` | Implemented |
| `test_initialize_taxTooHigh_revert` | `protocol/test/core/FactoryAdminExt.t.sol` | `FOUNDRY_OFFLINE=true forge test --match-test test_initialize_taxTooHigh_revert` | Implemented |
| `test_initialize_sellTax100pct_revert` | `protocol/test/core/FactoryAdminExt.t.sol` | `FOUNDRY_OFFLINE=true forge test --match-test test_initialize_sellTax100pct_revert` | Implemented |
| `test_atomicInit_noTaxFreeWindow` | `protocol/test/core/FactoryAdminExt.t.sol` | `FOUNDRY_OFFLINE=true forge test --match-test test_atomicInit_noTaxFreeWindow` | Implemented |
| `test_pairAdmin_immutable` | `protocol/test/core/FactoryAdminExt.t.sol` | `FOUNDRY_OFFLINE=true forge test --match-test test_pairAdmin_immutable` | Implemented |
| `test_routerQuote_matchesExecution` | `protocol/test/periphery/RouterQuoteParity.t.sol` | `FOUNDRY_OFFLINE=true forge test --match-test test_routerQuote_matchesExecution` | Implemented |
| `test_getAmountsIn_ceilRounding` | `protocol/test/periphery/RouterQuoteParity.t.sol` | `FOUNDRY_OFFLINE=true forge test --match-test test_getAmountsIn_ceilRounding` | Implemented |
| `test_rounding_boundary_1wei` | `protocol/test/periphery/RouterQuoteParity.t.sol` | `FOUNDRY_OFFLINE=true forge test --match-test test_rounding_boundary_1wei` | Implemented |
| `test_library_buyTax_matchesPair` | `protocol/test/periphery/RouterQuoteParity.t.sol` | `FOUNDRY_OFFLINE=true forge test --match-test test_library_buyTax_matchesPair` | Implemented |
| `test_library_multihop_taxPerHop` | `protocol/test/periphery/RouterQuoteParity.t.sol` | `FOUNDRY_OFFLINE=true forge test --match-test test_library_multihop_taxPerHop` | Implemented |
| `test_library_getAmountsIn_buyGrossUp` | `protocol/test/periphery/RouterQuoteParity.t.sol` | `FOUNDRY_OFFLINE=true forge test --match-test test_library_getAmountsIn_buyGrossUp` | Implemented |
| `test_library_lpFee_998` | `protocol/test/periphery/RouterLibrary.t.sol` | `FOUNDRY_OFFLINE=true forge test --match-test test_library_lpFee_998` | Implemented |
| `test_pairFor_usesFactoryGetPair` | `protocol/test/periphery/RouterLibrary.t.sol` | `FOUNDRY_OFFLINE=true forge test --match-test test_pairFor_usesFactoryGetPair` | Implemented |
| `test_routerQuote_liquidityEdge_expectRevert` | `protocol/test/periphery/RouterQuoteParity.t.sol` | `FOUNDRY_OFFLINE=true forge test --match-test test_routerQuote_liquidityEdge_expectRevert` | Implemented |
| `test_router_noPairRevert` | `protocol/test/periphery/RouterLibrary.t.sol` | `FOUNDRY_OFFLINE=true forge test --match-test test_router_noPairRevert` | Implemented |
| `test_sellExactIn_safeMargin_avoidsLiquidityEdge` | `protocol/test/periphery/RouterLibrary.t.sol` | `FOUNDRY_OFFLINE=true forge test --match-test test_sellExactIn_safeMargin_avoidsLiquidityEdge` | Implemented |
| `test_quoteToken_fot_vaultDrift` | `protocol/test/periphery/PolicyEnforcement.t.sol` | `FOUNDRY_OFFLINE=true forge test --match-test test_quoteToken_fot_vaultDrift` | Implemented |
| `test_quoteToken_notSupported` | `protocol/test/periphery/PolicyEnforcement.t.sol` | `FOUNDRY_OFFLINE=true forge test --match-test test_quoteToken_notSupported` | Implemented |
| `test_baseToken_policy_unrestricted` | `protocol/test/periphery/PolicyEnforcement.t.sol` | `FOUNDRY_OFFLINE=true forge test --match-test test_baseToken_policy_unrestricted` | Implemented |
| `test_router_supportingFOT_notSupported` | `protocol/test/periphery/RouterLibrary.t.sol` | `FOUNDRY_OFFLINE=true forge test --match-test test_router_supportingFOT_notSupported` | Implemented |
| `test_safeTransfer_nonStandard` | `protocol/test/core/ClaimTaxAdvanced.t.sol` | `FOUNDRY_OFFLINE=true forge test --match-test test_safeTransfer_nonStandard` | Implemented |
| `test_firstDeposit_minimumLiquidity` | `protocol/test/core/PairLifecycle.t.sol` | `FOUNDRY_OFFLINE=true forge test --match-test test_firstDeposit_minimumLiquidity` | Implemented |
| `test_claim_CEI_order` | `protocol/test/core/ClaimTaxAdvanced.t.sol` | `FOUNDRY_OFFLINE=true forge test --match-test test_claim_CEI_order` | Implemented |
| `invariant_raw_quote_eq_reserve_plus_vault_or_dust` | `protocol/test/invariant/StatefulPairInvariant.t.sol` | `FOUNDRY_OFFLINE=true forge test --match-path "test/invariant/**" --match-test invariant_raw_quote_eq_reserve_plus_vault_or_dust` | Implemented |
| `invariant_vault_monotonic_except_claim` | `protocol/test/invariant/StatefulPairInvariant.t.sol` | `FOUNDRY_OFFLINE=true forge test --match-path "test/invariant/**" --match-test invariant_vault_monotonic_except_claim` | Implemented |
| `invariant_totalSupply_implies_positive_reserves` | `protocol/test/invariant/StatefulPairInvariant.t.sol` | `FOUNDRY_OFFLINE=true forge test --match-path "test/invariant/**" --match-test invariant_totalSupply_implies_positive_reserves` | Implemented |
| `invariant_factory_pair_mapping_consistency` | `protocol/test/invariant/StatefulPairInvariant.t.sol` | `FOUNDRY_OFFLINE=true forge test --match-path "test/invariant/**" --match-test invariant_factory_pair_mapping_consistency` | Implemented |
| `invariant_router_quote_exec_error_le_1wei_executable_domain` | `protocol/test/invariant/StatefulPairInvariant.t.sol` | `FOUNDRY_OFFLINE=true forge test --match-path "test/invariant/**" --match-test invariant_router_quote_exec_error_le_1wei_executable_domain` | Implemented |
