pragma solidity =0.5.16;

import "./helpers/ForkFixture.sol";

contract ForkFuzzLiteTest is ForkFixture {
    function setUp() public {
        _setUpFork();
    }

    function testForkFuzz_buyTax_floor_alignment(uint96 rawInSeed) public onlyFork {
        uint256 rawIn = uint256(rawInSeed) % (20 ether);
        vm.assume(rawIn > 0);
        (uint256 rq, uint256 rb) = _reservesQuoteBase();
        uint256 tax = rawIn * pair.buyTaxBps() / BPS;
        uint256 effIn = rawIn - tax;
        uint256 out = _getAmountOut(effIn, rq, rb);
        vm.assume(out > 0);
        uint256 v0 = pair.accumulatedQuoteFees();
        _buy(rawIn, out, TRADER);
        uint256 v1 = pair.accumulatedQuoteFees();
        assertEq(v1 - v0, tax, "buy tax fuzz mismatch");
    }

    function testForkFuzz_sellTax_ceil_alignment(uint96 netOutSeed) public onlyFork {
        (uint256 rq, uint256 rb) = _reservesQuoteBase();
        uint256 cap = rq / 100;
        vm.assume(cap > 1);
        uint256 netOut = uint256(netOutSeed) % cap;
        vm.assume(netOut > 0);
        uint256 grossOut = _ceilDiv(netOut * BPS, BPS - pair.sellTaxBps());
        vm.assume(grossOut < rq);
        uint256 inBase = _getAmountIn(grossOut, rb, rq);
        uint256 v0 = pair.accumulatedQuoteFees();
        _sell(inBase, netOut, TRADER);
        uint256 v1 = pair.accumulatedQuoteFees();
        assertEq(v1 - v0, grossOut - netOut, "sell tax fuzz mismatch");
    }

    function testForkFuzz_routerParity_bound(uint96 inSeed) public onlyFork {
        uint256 inAmount = uint256(inSeed) % (15 ether);
        vm.assume(inAmount > 0);
        address[] memory p = _path(monadQuoteToken, monadBaseToken);
        uint256[] memory quoted = router.getAmountsOut(inAmount, p);
        vm.assume(quoted[1] > 0);
        _fundQuote(TRADER, inAmount);
        _approveRouter(monadQuoteToken, TRADER, uint256(-1));
        uint256 b0 = _baseBalance(TRADER);
        vm.prank(TRADER);
        router.swapExactTokensForTokens(inAmount, 0, p, TRADER, block.timestamp + 1);
        uint256 got = _baseBalance(TRADER) - b0;
        assertLe(_absDiff(got, quoted[1]), 1, "router parity fuzz bound");
    }
}
