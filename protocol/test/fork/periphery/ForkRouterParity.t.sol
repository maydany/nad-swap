pragma solidity =0.5.16;

import "../helpers/ForkFixture.sol";
import "../../helpers/MockERC20.sol";

contract ForkRouterParityTest is ForkFixture {
    function setUp() public {
        _setUpFork();
    }

    function testFork_router_quote_matchesExecution_quoteToBase() public onlyFork {
        uint256 inAmount = 10 ether;
        address[] memory p = _path(monadQuoteToken, monadBaseToken);
        uint256[] memory quoted = router.getAmountsOut(inAmount, p);

        _fundQuote(TRADER, inAmount);
        _approveRouter(monadQuoteToken, TRADER, uint256(-1));
        uint256 b0 = _baseBalance(TRADER);
        vm.prank(TRADER);
        router.swapExactTokensForTokens(inAmount, 0, p, TRADER, block.timestamp + 1);
        uint256 got = _baseBalance(TRADER) - b0;
        assertEq(got, quoted[1], "quote/execution mismatch");
    }

    function testFork_router_quote_matchesExecution_baseToQuote() public onlyFork {
        uint256 inAmount = 5 ether;
        address[] memory p = _path(monadBaseToken, monadQuoteToken);
        uint256[] memory quoted = router.getAmountsOut(inAmount, p);
        _fundBase(TRADER, inAmount);
        _approveRouter(monadBaseToken, TRADER, uint256(-1));
        uint256 q0 = _quoteBalance(TRADER);
        vm.prank(TRADER);
        router.swapExactTokensForTokens(inAmount, 0, p, TRADER, block.timestamp + 1);
        uint256 got = _quoteBalance(TRADER) - q0;
        assertLe(_absDiff(got, quoted[1]), 1, "quote/execution >1 wei");
    }

    function testFork_router_getAmountsIn_ceilRounding() public onlyFork {
        uint256 outAmount = 1 ether;
        address[] memory p = _path(monadQuoteToken, monadBaseToken);
        uint256[] memory amountsIn = router.getAmountsIn(outAmount, p);
        _fundQuote(TRADER, amountsIn[0]);
        _approveRouter(monadQuoteToken, TRADER, uint256(-1));
        vm.prank(TRADER);
        expectRevertMsg("UniswapV2Router: EXCESSIVE_INPUT_AMOUNT");
        router.swapTokensForExactTokens(outAmount, amountsIn[0] - 1, p, TRADER, block.timestamp + 1);
    }

    function testFork_router_rounding_boundary_within1wei() public onlyFork {
        uint256 inAmount = 7 ether;
        address[] memory p = _path(monadBaseToken, monadQuoteToken);
        uint256[] memory quoted = router.getAmountsOut(inAmount, p);
        _fundBase(TRADER, inAmount);
        _approveRouter(monadBaseToken, TRADER, uint256(-1));
        uint256 q0 = _quoteBalance(TRADER);
        vm.prank(TRADER);
        router.swapExactTokensForTokens(inAmount, 0, p, TRADER, block.timestamp + 1);
        uint256 got = _quoteBalance(TRADER) - q0;
        assertLe(_absDiff(got, quoted[1]), 1, "boundary drift >1 wei");
    }

    function testFork_router_multihop_taxPerHop() public onlyFork {
        // Create second pair for multihop: quote <-> mid
        MockERC20 mid = new MockERC20("Mid", "MID", 18);
        vm.prank(PAIR_ADMIN);
        address pair2Addr = factory.createPair(monadQuoteToken, address(mid), 700, 200, COLLECTOR);
        UniswapV2Pair pair2 = UniswapV2Pair(pair2Addr);

        MockERC20(monadQuoteToken).mint(LP, 1_000_000 ether);
        mid.mint(LP, 1_000_000 ether);
        vm.prank(LP);
        _safeTokenTransfer(monadQuoteToken, pair2Addr, 1_000_000 ether);
        vm.prank(LP);
        mid.transfer(pair2Addr, 1_000_000 ether);
        vm.prank(LP);
        pair2.mint(LP);

        address[] memory p = _path3(monadBaseToken, monadQuoteToken, address(mid));
        uint256 inAmount = 3 ether;
        uint256[] memory quoted = router.getAmountsOut(inAmount, p);
        _fundBase(TRADER, inAmount);
        _approveRouter(monadBaseToken, TRADER, uint256(-1));
        uint256 m0 = mid.balanceOf(TRADER);
        vm.prank(TRADER);
        router.swapExactTokensForTokens(inAmount, 0, p, TRADER, block.timestamp + 1);
        uint256 got = mid.balanceOf(TRADER) - m0;
        assertLe(_absDiff(got, quoted[2]), 2, "multihop drift >2 wei");
    }

    function testFork_router_noPair_revert() public onlyFork {
        MockERC20 x = new MockERC20("X", "X", 18);
        MockERC20 y = new MockERC20("Y", "Y", 18);
        x.mint(TRADER, 1 ether);
        y.mint(TRADER, 1 ether);
        vm.prank(TRADER);
        x.approve(address(router), uint256(-1));
        vm.prank(TRADER);
        y.approve(address(router), uint256(-1));
        vm.prank(TRADER);
        expectRevertMsg("PAIR_NOT_CREATED");
        router.addLiquidity(address(x), address(y), 1 ether, 1 ether, 0, 0, TRADER, block.timestamp + 1);
    }

    function testFork_router_sellExactIn_safeMargin_path() public onlyFork {
        uint256 inAmount = 8 ether;
        address[] memory p = _path(monadBaseToken, monadQuoteToken);
        uint256[] memory quoted = router.getAmountsOut(inAmount, p);
        (uint256 rq, uint256 rb) = _reservesQuoteBase();
        uint256 grossOut = _getAmountOut(inAmount, rb, rq);
        uint256 expected = (grossOut * (BPS - pair.sellTaxBps())) / BPS;
        assertEq(quoted[1], expected, "sell exact-in quote mismatch");
    }

    function testFork_router_taxRace_slippage() public onlyFork {
        uint256 inAmount = 6 ether;
        address[] memory p = _path(monadQuoteToken, monadBaseToken);
        uint256[] memory beforeQuote = router.getAmountsOut(inAmount, p);
        uint16 currentSellTax = pair.sellTaxBps();
        vm.prank(PAIR_ADMIN);
        factory.setTaxConfig(address(pair), 2_000, currentSellTax, COLLECTOR);
        _fundQuote(TRADER, inAmount);
        _approveRouter(monadQuoteToken, TRADER, uint256(-1));
        expectRevertMsg("UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT");
        vm.prank(TRADER);
        router.swapExactTokensForTokens(inAmount, beforeQuote[1], p, TRADER, block.timestamp + 1);
    }
}
