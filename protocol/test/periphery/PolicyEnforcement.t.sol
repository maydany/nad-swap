pragma solidity =0.5.16;

import "./../helpers/PairFixture.sol";
import "./../helpers/MockFeeOnTransferERC20.sol";
import "./../helpers/MockERC20.sol";
import "./../helpers/MockWETH.sol";

contract PolicyEnforcementTest is PairFixture {
    function setUp() public {
        _setUpPair(300, 500);
    }

    function test_quoteToken_notSupported() public {
        uint256 amountIn = 1000 ether;
        _mintToken(quoteTokenAddr, TRADER, amountIn);
        _approveRouter(quoteTokenAddr, TRADER, uint256(-1));
        vm.prank(PAIR_ADMIN);
        factory.setQuoteToken(quoteTokenAddr, false);

        address[] memory p = _path(quoteTokenAddr, baseTokenAddr);
        vm.prank(TRADER);
        expectRevertMsg("QUOTE_NOT_SUPPORTED");
        router.swapExactTokensForTokens(amountIn, 0, p, TRADER, block.timestamp + 1);
    }

    function test_baseToken_policy_unrestricted() public {
        MockERC20 q = new MockERC20("Quote3", "Q3", 18);
        MockERC20 b = new MockERC20("Base3", "B3", 18);
        MockWETH w = new MockWETH();
        UniswapV2Factory f = new UniswapV2Factory(PAIR_ADMIN);
        UniswapV2Router02 r = new UniswapV2Router02(address(f), address(w));

        vm.prank(PAIR_ADMIN);
        f.setQuoteToken(address(q), true);
        vm.prank(PAIR_ADMIN);
        address pairAddr = f.createPair(address(q), address(b), 300, 500, COLLECTOR);
        UniswapV2Pair p = UniswapV2Pair(pairAddr);

        q.mint(LP, 1_000_000 ether);
        b.mint(LP, 1_000_000 ether);
        vm.prank(LP);
        q.transfer(pairAddr, 1_000_000 ether);
        vm.prank(LP);
        b.transfer(pairAddr, 1_000_000 ether);
        vm.prank(LP);
        p.mint(LP);

        q.mint(TRADER, 1000 ether);
        vm.prank(TRADER);
        q.approve(address(r), uint256(-1));

        address[] memory path = new address[](2);
        path[0] = address(q);
        path[1] = address(b);
        uint256 baseBefore = b.balanceOf(TRADER);
        vm.prank(TRADER);
        r.swapExactTokensForTokens(1000 ether, 0, path, TRADER, block.timestamp + 1);
        uint256 baseAfter = b.balanceOf(TRADER);
        assertGt(baseAfter - baseBefore, 0, "base token path unexpectedly blocked");
    }

    function test_baseToken_fot_sellExactIn_routerReverts() public {
        MockERC20 q = new MockERC20("QuoteF", "QF", 18);
        MockFeeOnTransferERC20 b = new MockFeeOnTransferERC20("BaseFOT", "BFOT", 18, 100);
        MockWETH w = new MockWETH();
        UniswapV2Factory f = new UniswapV2Factory(PAIR_ADMIN);
        UniswapV2Router02 r = new UniswapV2Router02(address(f), address(w));

        vm.prank(PAIR_ADMIN);
        f.setQuoteToken(address(q), true);
        vm.prank(PAIR_ADMIN);
        address pairAddr = f.createPair(address(q), address(b), 300, 500, COLLECTOR);
        UniswapV2Pair p = UniswapV2Pair(pairAddr);

        q.mint(LP, 1_200_000 ether);
        b.mint(LP, 1_200_000 ether);
        vm.prank(LP);
        q.transfer(pairAddr, 1_000_000 ether);
        vm.prank(LP);
        b.transfer(pairAddr, 1_000_000 ether);
        vm.prank(LP);
        p.mint(LP);

        uint256 amountIn = 1000 ether;
        b.mint(TRADER, amountIn);
        vm.prank(TRADER);
        b.approve(address(r), uint256(-1));

        address[] memory path = new address[](2);
        path[0] = address(b);
        path[1] = address(q);

        vm.prank(TRADER);
        (bool success,) = address(r).call(
            abi.encodeWithSelector(
                r.swapExactTokensForTokens.selector,
                amountIn,
                uint256(0),
                path,
                TRADER,
                block.timestamp + 1
            )
        );
        assertTrue(!success, "base FOT sell exact-in should revert");
    }

    function test_baseToken_fot_buyExactIn_recipientReceivesLessThanQuoted() public {
        MockERC20 q = new MockERC20("QuoteF2", "QF2", 18);
        MockFeeOnTransferERC20 b = new MockFeeOnTransferERC20("BaseFOT2", "BFOT2", 18, 100);
        MockWETH w = new MockWETH();
        UniswapV2Factory f = new UniswapV2Factory(PAIR_ADMIN);
        UniswapV2Router02 r = new UniswapV2Router02(address(f), address(w));

        vm.prank(PAIR_ADMIN);
        f.setQuoteToken(address(q), true);
        vm.prank(PAIR_ADMIN);
        address pairAddr = f.createPair(address(q), address(b), 300, 500, COLLECTOR);
        UniswapV2Pair p = UniswapV2Pair(pairAddr);

        q.mint(LP, 1_200_000 ether);
        b.mint(LP, 1_200_000 ether);
        vm.prank(LP);
        q.transfer(pairAddr, 1_000_000 ether);
        vm.prank(LP);
        b.transfer(pairAddr, 1_000_000 ether);
        vm.prank(LP);
        p.mint(LP);

        uint256 quoteIn = 1000 ether;
        q.mint(TRADER, quoteIn);
        vm.prank(TRADER);
        q.approve(address(r), uint256(-1));

        address[] memory path = new address[](2);
        path[0] = address(q);
        path[1] = address(b);
        uint256[] memory quoted = r.getAmountsOut(quoteIn, path);

        uint256 baseBefore = b.balanceOf(TRADER);
        vm.prank(TRADER);
        r.swapExactTokensForTokens(quoteIn, quoted[1], path, TRADER, block.timestamp + 1);
        uint256 received = b.balanceOf(TRADER) - baseBefore;

        assertGt(received, 0, "base FOT buy returned zero");
        assertLt(received, quoted[1], "base FOT buy should shortfall vs quote");
    }

    function test_quoteToken_fot_vaultDrift() public {
        MockFeeOnTransferERC20 q = new MockFeeOnTransferERC20("FOT-Quote", "FOTQ", 18, 100);
        MockERC20 b = new MockERC20("Base4", "B4", 18);
        UniswapV2Factory f = new UniswapV2Factory(PAIR_ADMIN);

        vm.prank(PAIR_ADMIN);
        f.setQuoteToken(address(q), true);
        vm.prank(PAIR_ADMIN);
        address pairAddr = f.createPair(address(q), address(b), 300, 500, COLLECTOR);
        UniswapV2Pair p = UniswapV2Pair(pairAddr);

        q.mint(LP, 1_200_000 ether);
        b.mint(LP, 1_200_000 ether);
        vm.prank(LP);
        q.transfer(pairAddr, 1_000_000 ether);
        vm.prank(LP);
        b.transfer(pairAddr, 1_000_000 ether);
        vm.prank(LP);
        p.mint(LP);

        (uint112 r0, uint112 r1,) = p.getReserves();
        uint256 rq = p.quoteToken() == p.token0() ? uint256(r0) : uint256(r1);
        uint256 rb = p.quoteToken() == p.token0() ? uint256(r1) : uint256(r0);
        uint256 netQuoteOut = 200 ether;
        uint256 grossQuoteOut = _ceilDiv(netQuoteOut * BPS, BPS - p.sellTaxBps());
        uint256 baseIn = _getAmountIn(grossQuoteOut, rb, rq);
        b.mint(TRADER, baseIn);
        vm.prank(TRADER);
        b.transfer(pairAddr, baseIn);
        if (p.quoteToken() == p.token0()) {
            vm.prank(TRADER);
            p.swap(netQuoteOut, 0, TRADER, new bytes(0));
        } else {
            vm.prank(TRADER);
            p.swap(0, netQuoteOut, TRADER, new bytes(0));
        }

        uint256 taxAmount = p.accumulatedQuoteTax();
        assertGt(taxAmount, 0, "tax not accrued");
        uint256 rawQuote = q.balanceOf(pairAddr);
        uint256 burnAmount = rawQuote - taxAmount + 1;
        q.burn(pairAddr, burnAmount);

        expectRevertMsg("VAULT_DRIFT");
        p.sync();
    }
}
