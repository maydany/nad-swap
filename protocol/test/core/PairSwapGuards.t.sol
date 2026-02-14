pragma solidity =0.5.16;

import "./../helpers/PairFixture.sol";

contract PairSwapGuardsTest is PairFixture {
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );

    function setUp() public {
        _setUpPair(300, 500);
    }

    function test_directCall_cannotBypassTax() public {
        (uint256 rq, uint256 rb) = _reservesQuoteBase();
        uint256 rawIn = 1000 ether;
        uint256 expectedTax = rawIn * pair.buyTaxBps() / BPS;
        uint256 effIn = rawIn - expectedTax;
        uint256 baseOut = _getAmountOut(effIn, rq, rb);

        uint256 vaultBefore = pair.accumulatedQuoteFees();
        _buy(rawIn, baseOut, TRADER);
        uint256 vaultAfter = pair.accumulatedQuoteFees();

        assertEq(vaultAfter - vaultBefore, expectedTax, "direct swap bypassed buy tax");
    }

    function test_kInvariant_afterTaxedSwap() public {
        (uint256 rqBefore, uint256 rbBefore) = _reservesQuoteBase();
        uint256 kBefore = rqBefore * rbBefore;

        uint256 rawIn = 2_000 ether;
        uint256 effIn = rawIn - (rawIn * pair.buyTaxBps() / BPS);
        uint256 baseOut = _getAmountOut(effIn, rqBefore, rbBefore);
        _buy(rawIn, baseOut, TRADER);

        (uint256 rqAfter, uint256 rbAfter) = _reservesQuoteBase();
        uint256 kAfter = rqAfter * rbAfter;
        assertGe(kAfter, kBefore, "K invariant decreased");
    }

    function test_vaultOverflow_revert() public {
        _mintToken(quoteTokenAddr, address(pair), uint256(uint96(-1)));
        _setVault(uint96(-1) - 1);

        (uint256 rq, uint256 rb) = _reservesQuoteBase();
        uint256 rawIn = 1000 ether;
        uint256 effIn = rawIn - (rawIn * pair.buyTaxBps() / BPS);
        uint256 baseOut = _getAmountOut(effIn, rq, rb);

        _mintToken(quoteTokenAddr, TRADER, rawIn);
        vm.prank(TRADER);
        _safeTokenTransfer(quoteTokenAddr, address(pair), rawIn);

        bool quote0 = _isQuote0();
        expectRevertMsg("VAULT_OVERFLOW");
        vm.prank(TRADER);
        if (quote0) {
            pair.swap(0, baseOut, TRADER, new bytes(0));
        } else {
            pair.swap(baseOut, 0, TRADER, new bytes(0));
        }
    }

    function test_kMultiplyOverflow_revert() public {
        uint256 hugeBaseIn = 10**60;
        uint256 netQuoteOut = 1;

        _mintToken(baseTokenAddr, TRADER, hugeBaseIn);
        vm.prank(TRADER);
        _safeTokenTransfer(baseTokenAddr, address(pair), hugeBaseIn);

        bool quote0 = _isQuote0();
        expectRevertMsg("K_MULTIPLY_OVERFLOW");
        vm.prank(TRADER);
        if (quote0) {
            pair.swap(netQuoteOut, 0, TRADER, new bytes(0));
        } else {
            pair.swap(0, netQuoteOut, TRADER, new bytes(0));
        }
    }

    function test_swap_insufficientLiquidity() public {
        (uint112 r0,,) = pair.getReserves();
        vm.prank(TRADER);
        expectRevertMsg("INSUFFICIENT_LIQUIDITY");
        pair.swap(uint256(r0), 0, TRADER, new bytes(0));
    }

    function test_swap_vaultDrift_oldVault_revert() public {
        (uint256 rawQuote,) = _rawQuoteBase();
        _setVault(uint96(rawQuote + 1));

        bool quote0 = _isQuote0();
        expectRevertMsg("VAULT_DRIFT");
        vm.prank(TRADER);
        if (quote0) {
            pair.swap(0, 1, TRADER, new bytes(0));
        } else {
            pair.swap(1, 0, TRADER, new bytes(0));
        }
    }

    function test_swap_vaultDrift_newVault_revert() public {
        (uint256 rawQuote,) = _rawQuoteBase();
        _setVault(uint96(rawQuote - 1));

        (uint256 rq, uint256 rb) = _reservesQuoteBase();
        uint256 netQuoteOut = 1 ether;
        uint256 grossQuoteOut = _ceilDiv(netQuoteOut * BPS, BPS - pair.sellTaxBps());
        uint256 baseIn = _getAmountIn(grossQuoteOut, rb, rq);

        _mintToken(baseTokenAddr, TRADER, baseIn);
        vm.prank(TRADER);
        _safeTokenTransfer(baseTokenAddr, address(pair), baseIn);

        bool quote0 = _isQuote0();
        expectRevertMsg("VAULT_DRIFT");
        vm.prank(TRADER);
        if (quote0) {
            pair.swap(netQuoteOut, 0, TRADER, new bytes(0));
        } else {
            pair.swap(0, netQuoteOut, TRADER, new bytes(0));
        }
    }

    function test_sell_grossOut_exceedsReserve() public {
        (uint256 rq,) = _reservesQuoteBase();
        uint256 netQuoteOut = rq - 1;
        bool quote0 = _isQuote0();
        expectRevertMsg("INSUFFICIENT_LIQUIDITY_GROSS");
        vm.prank(TRADER);
        if (quote0) {
            pair.swap(netQuoteOut, 0, TRADER, new bytes(0));
        } else {
            pair.swap(0, netQuoteOut, TRADER, new bytes(0));
        }
    }

    function test_sell_exactIn_liquidityEdge() public {
        (uint256 rq,) = _reservesQuoteBase();
        uint256 netQuoteOut = rq * (BPS - pair.sellTaxBps()) / BPS;
        bool quote0 = _isQuote0();
        expectRevertMsg("INSUFFICIENT_LIQUIDITY_GROSS");
        vm.prank(TRADER);
        if (quote0) {
            pair.swap(netQuoteOut, 0, TRADER, new bytes(0));
        } else {
            pair.swap(0, netQuoteOut, TRADER, new bytes(0));
        }
    }

    function test_buy_sell_sequential() public {
        (uint256 rq, uint256 rb) = _reservesQuoteBase();

        uint256 rawBuy = 2_000 ether;
        uint256 buyEffIn = rawBuy - (rawBuy * pair.buyTaxBps() / BPS);
        uint256 buyBaseOut = _getAmountOut(buyEffIn, rq, rb);
        _buy(rawBuy, buyBaseOut, TRADER);
        uint256 afterBuyVault = pair.accumulatedQuoteFees();

        (rq, rb) = _reservesQuoteBase();
        uint256 netQuoteOut = 150 ether;
        uint256 grossQuoteOut = _ceilDiv(netQuoteOut * BPS, BPS - pair.sellTaxBps());
        uint256 sellBaseIn = _getAmountIn(grossQuoteOut, rb, rq);
        _sell(sellBaseIn, netQuoteOut, TRADER);
        uint256 afterSellVault = pair.accumulatedQuoteFees();

        assertGt(afterBuyVault, 0, "buy did not accrue vault");
        assertGt(afterSellVault, afterBuyVault, "sell did not accrue additional vault");
    }

    function test_swapEvent_usesEffIn() public {
        (uint256 rqBefore, uint256 rb) = _reservesQuoteBase();
        uint256 rawIn = 3_000 ether;
        uint256 taxIn = rawIn * pair.buyTaxBps() / BPS;
        uint256 effIn = rawIn - taxIn;
        uint256 baseOut = _getAmountOut(effIn, rqBefore, rb);

        uint256 amount0Out = _isQuote0() ? 0 : baseOut;
        uint256 amount1Out = _isQuote0() ? baseOut : 0;
        uint256 effIn0 = _isQuote0() ? effIn : 0;
        uint256 effIn1 = _isQuote0() ? 0 : effIn;

        _mintToken(quoteTokenAddr, TRADER, rawIn);
        vm.prank(TRADER);
        _safeTokenTransfer(quoteTokenAddr, address(pair), rawIn);

        vm.expectEmit(true, true, false, true, address(pair));
        emit Swap(TRADER, effIn0, effIn1, amount0Out, amount1Out, TRADER);

        vm.prank(TRADER);
        pair.swap(amount0Out, amount1Out, TRADER, new bytes(0));
        (uint256 rqAfter,) = _reservesQuoteBase();
        assertEq(rqAfter - rqBefore, effIn, "effective input mismatch");
    }

    function test_singleSide_swapExactTokens() public {
        uint256 amountIn = 1000 ether;
        _mintToken(quoteTokenAddr, TRADER, amountIn);
        _approveRouter(quoteTokenAddr, TRADER, uint256(-1));

        address[] memory p = _path(quoteTokenAddr, baseTokenAddr);
        uint256 beforeOut = _baseBalance(TRADER);
        vm.prank(TRADER);
        router.swapExactTokensForTokens(amountIn, 0, p, TRADER, block.timestamp + 1);
        uint256 afterOut = _baseBalance(TRADER);

        assertGt(afterOut, beforeOut, "swapExactTokens did not execute");
    }

    function test_singleSide_swapForExactTokens() public {
        uint256 wantOut = 100 ether;
        address[] memory p = _path(quoteTokenAddr, baseTokenAddr);
        uint256[] memory amountsIn = router.getAmountsIn(wantOut, p);
        _mintToken(quoteTokenAddr, TRADER, amountsIn[0]);
        _approveRouter(quoteTokenAddr, TRADER, uint256(-1));

        vm.prank(TRADER);
        router.swapTokensForExactTokens(wantOut, amountsIn[0], p, TRADER, block.timestamp + 1);

        assertEq(_baseBalance(TRADER), wantOut, "exact-out swap failed");
    }

    function test_singleSide_flashCallback() public {
        vm.prank(TRADER);
        expectRevertMsg("SINGLE_SIDE_ONLY");
        pair.swap(1, 1, address(0x1234), hex"01");
    }
}
