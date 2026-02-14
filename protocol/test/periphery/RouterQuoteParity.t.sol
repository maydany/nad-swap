pragma solidity =0.5.16;

import "./../helpers/PairFixture.sol";
import "./../helpers/MockERC20.sol";

contract RouterQuoteParityTest is PairFixture {
    function setUp() public {
        _setUpPair(300, 500);
    }

    function _absDiff(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a - b : b - a;
    }

    function _reservesForPath(address pairAddr, address tokenIn, address tokenOut)
        internal
        view
        returns (uint256 reserveIn, uint256 reserveOut)
    {
        (uint112 r0, uint112 r1,) = IUniswapV2Pair(pairAddr).getReserves();
        if (tokenIn == IUniswapV2Pair(pairAddr).token0() && tokenOut == IUniswapV2Pair(pairAddr).token1()) {
            reserveIn = uint256(r0);
            reserveOut = uint256(r1);
        } else {
            reserveIn = uint256(r1);
            reserveOut = uint256(r0);
        }
    }

    function test_routerQuote_matchesExecution() public {
        uint256 amountIn = 1_000 ether;
        address[] memory p = _path(quoteTokenAddr, baseTokenAddr);
        uint256[] memory amounts = router.getAmountsOut(amountIn, p);

        _mintToken(quoteTokenAddr, TRADER, amountIn);
        _approveRouter(quoteTokenAddr, TRADER, uint256(-1));
        uint256 beforeOut = _baseBalance(TRADER);
        vm.prank(TRADER);
        router.swapExactTokensForTokens(amountIn, 0, p, TRADER, block.timestamp + 1);
        uint256 afterOut = _baseBalance(TRADER);

        assertEq(afterOut - beforeOut, amounts[1], "router quote != execution");
    }

    function test_getAmountsIn_ceilRounding() public {
        uint256 outAmount = 100 ether;
        address[] memory p = _path(quoteTokenAddr, baseTokenAddr);
        uint256[] memory quoted = router.getAmountsIn(outAmount, p);

        _mintToken(quoteTokenAddr, TRADER, quoted[0]);
        _approveRouter(quoteTokenAddr, TRADER, uint256(-1));

        vm.prank(TRADER);
        expectRevertMsg("UniswapV2Router: EXCESSIVE_INPUT_AMOUNT");
        router.swapTokensForExactTokens(outAmount, quoted[0] - 1, p, TRADER, block.timestamp + 1);

        vm.prank(TRADER);
        router.swapTokensForExactTokens(outAmount, quoted[0], p, TRADER, block.timestamp + 1);
        assertEq(_baseBalance(TRADER), outAmount, "exact-out did not settle");
    }

    function test_rounding_boundary_1wei() public {
        uint256 amountIn = 1_000 ether;
        address[] memory p = _path(baseTokenAddr, quoteTokenAddr);
        address pairAddr = factory.getPair(baseTokenAddr, quoteTokenAddr);
        (uint256 reserveIn, uint256 reserveOut) = _reservesForPath(pairAddr, baseTokenAddr, quoteTokenAddr);

        uint256 grossOut = _getAmountOut(amountIn, reserveIn, reserveOut);
        uint256 expectedNet = grossOut > 0 ? ((grossOut - 1) * (BPS - pair.sellTaxBps())) / BPS : 0;
        uint256[] memory quoted = router.getAmountsOut(amountIn, p);
        assertEq(quoted[1], expectedNet, "router safe-margin rounding mismatch");

        _mintToken(baseTokenAddr, TRADER, amountIn);
        _approveRouter(baseTokenAddr, TRADER, uint256(-1));
        uint256 beforeOut = _quoteBalance(TRADER);
        vm.prank(TRADER);
        router.swapExactTokensForTokens(amountIn, 0, p, TRADER, block.timestamp + 1);
        uint256 executed = _quoteBalance(TRADER) - beforeOut;

        assertLe(_absDiff(executed, quoted[1]), 1, "execution/quote delta > 1 wei");
    }

    function test_library_buyTax_matchesPair() public {
        uint256 amountIn = 2_000 ether;
        address[] memory p = _path(quoteTokenAddr, baseTokenAddr);
        uint256[] memory quoted = router.getAmountsOut(amountIn, p);
        uint256 expectedTax = amountIn * pair.buyTaxBps() / BPS;

        uint256 vaultBefore = pair.accumulatedQuoteFees();
        _buy(amountIn, quoted[1], TRADER);
        uint256 vaultAfter = pair.accumulatedQuoteFees();
        assertEq(vaultAfter - vaultBefore, expectedTax, "library buy-tax mismatch");
    }

    function test_library_multihop_taxPerHop() public {
        MockERC20 mid = new MockERC20("Mid", "MID", 18);
        vm.prank(FEE_TO_SETTER);
        factory.setBaseTokenSupported(address(mid), true);
        vm.prank(PAIR_ADMIN);
        address pair2Addr = factory.createPair(quoteTokenAddr, address(mid), 700, 200, COLLECTOR);
        UniswapV2Pair pair2 = UniswapV2Pair(pair2Addr);

        _mintToken(quoteTokenAddr, LP, 1_000_000 ether);
        mid.mint(LP, 1_000_000 ether);
        vm.prank(LP);
        _safeTokenTransfer(quoteTokenAddr, pair2Addr, 1_000_000 ether);
        vm.prank(LP);
        mid.transfer(pair2Addr, 1_000_000 ether);
        vm.prank(LP);
        pair2.mint(LP);

        address[] memory path3 = new address[](3);
        path3[0] = baseTokenAddr;
        path3[1] = quoteTokenAddr;
        path3[2] = address(mid);

        uint256 amountIn = 1200 ether;
        uint256[] memory quoted = router.getAmountsOut(amountIn, path3);

        (uint256 rb1, uint256 rq1) = _reservesForPath(address(pair), baseTokenAddr, quoteTokenAddr);
        uint256 grossQuote1 = _getAmountOut(amountIn, rb1, rq1);
        uint256 netQuote1 = grossQuote1 > 0 ? ((grossQuote1 - 1) * (BPS - pair.sellTaxBps())) / BPS : 0;

        (uint256 rq2, uint256 rm2) = _reservesForPath(pair2Addr, quoteTokenAddr, address(mid));
        uint256 buyTax2 = uint256(pair2.buyTaxBps());
        uint256 effIn2 = netQuote1 - (netQuote1 * buyTax2 / BPS);
        uint256 manualOut = _getAmountOut(effIn2, rq2, rm2);

        assertLe(_absDiff(quoted[2], manualOut), 2, "multihop tax drift > 2 wei");
    }

    function test_library_getAmountsIn_buyGrossUp() public {
        uint256 amountOut = 80 ether;
        address[] memory p = _path(quoteTokenAddr, baseTokenAddr);
        uint256[] memory quoted = router.getAmountsIn(amountOut, p);

        (uint256 rq, uint256 rb) = _reservesQuoteBase();
        uint256 netIn = _getAmountIn(amountOut, rq, rb);
        uint256 expectedRawIn = _ceilDiv(netIn * BPS, BPS - pair.buyTaxBps());
        assertEq(quoted[0], expectedRawIn, "buy gross-up mismatch");

        _mintToken(quoteTokenAddr, TRADER, quoted[0]);
        _approveRouter(quoteTokenAddr, TRADER, uint256(-1));
        vm.prank(TRADER);
        router.swapTokensForExactTokens(amountOut, quoted[0], p, TRADER, block.timestamp + 1);
        assertEq(_baseBalance(TRADER), amountOut, "exact-out buy execution mismatch");
    }

    function test_routerQuote_liquidityEdge_expectRevert() public {
        uint256 tinyIn = 1;
        address[] memory p = _path(baseTokenAddr, quoteTokenAddr);
        uint256[] memory quoted = router.getAmountsOut(tinyIn, p);
        assertEq(quoted[1], 0, "expected tiny quote to round to zero");

        _mintToken(baseTokenAddr, TRADER, tinyIn);
        _approveRouter(baseTokenAddr, TRADER, uint256(-1));
        vm.prank(TRADER);
        expectRevertMsg("INSUFFICIENT_OUTPUT");
        router.swapExactTokensForTokens(tinyIn, 0, p, TRADER, block.timestamp + 1);
    }

    function test_sell_exactIn_grossOut_diverge() public {
        uint256 amountIn = 1_000 ether;
        address pairAddr = factory.getPair(baseTokenAddr, quoteTokenAddr);
        (uint256 reserveIn, uint256 reserveOut) = _reservesForPath(pairAddr, baseTokenAddr, quoteTokenAddr);
        uint256 grossOut = _getAmountOut(amountIn, reserveIn, reserveOut);

        address[] memory p = _path(baseTokenAddr, quoteTokenAddr);
        uint256[] memory quoted = router.getAmountsOut(amountIn, p);
        uint256 pairGrossFromRouter = _ceilDiv(quoted[1] * BPS, BPS - pair.sellTaxBps());

        assertLe(_absDiff(grossOut, pairGrossFromRouter), 1, "grossOut divergence > 1 wei");
    }

    function test_taxChange_raceCond_slippage() public {
        uint256 amountIn = 2_000 ether;
        address[] memory p = _path(quoteTokenAddr, baseTokenAddr);
        uint256[] memory beforeQuote = router.getAmountsOut(amountIn, p);

        uint16 sellTax = pair.sellTaxBps();
        vm.prank(PAIR_ADMIN);
        factory.setTaxConfig(address(pair), 2_000, sellTax, COLLECTOR);

        _mintToken(quoteTokenAddr, TRADER, amountIn);
        _approveRouter(quoteTokenAddr, TRADER, uint256(-1));
        vm.prank(TRADER);
        expectRevertMsg("UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT");
        router.swapExactTokensForTokens(amountIn, beforeQuote[1], p, TRADER, block.timestamp + 1);
    }
}
