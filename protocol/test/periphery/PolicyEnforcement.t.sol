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

    function test_baseToken_fot_unsupported() public {
        MockERC20 q = new MockERC20("Quote3", "Q3", 18);
        MockFeeOnTransferERC20 b = new MockFeeOnTransferERC20("FOT-Base", "FOTB", 18, 100);
        MockWETH w = new MockWETH();
        UniswapV2Factory f = new UniswapV2Factory(PAIR_ADMIN);
        UniswapV2Router02 r = new UniswapV2Router02(address(f), address(w));

        vm.prank(PAIR_ADMIN);
        f.setQuoteToken(address(q), true);
        vm.prank(PAIR_ADMIN);
        f.setBaseTokenSupported(address(b), true);
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

        vm.prank(PAIR_ADMIN);
        f.setBaseTokenSupported(address(b), false);

        q.mint(TRADER, 1000 ether);
        vm.prank(TRADER);
        q.approve(address(r), uint256(-1));

        address[] memory path = new address[](2);
        path[0] = address(q);
        path[1] = address(b);
        vm.prank(TRADER);
        expectRevertMsg("BASE_NOT_SUPPORTED");
        r.swapExactTokensForTokens(1000 ether, 0, path, TRADER, block.timestamp + 1);
    }

    function test_quoteToken_fot_vaultDrift() public {
        MockFeeOnTransferERC20 q = new MockFeeOnTransferERC20("FOT-Quote", "FOTQ", 18, 100);
        MockERC20 b = new MockERC20("Base4", "B4", 18);
        UniswapV2Factory f = new UniswapV2Factory(PAIR_ADMIN);

        vm.prank(PAIR_ADMIN);
        f.setQuoteToken(address(q), true);
        vm.prank(PAIR_ADMIN);
        f.setBaseTokenSupported(address(b), true);
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

        uint256 fees = p.accumulatedQuoteFees();
        assertGt(fees, 0, "fees not accrued");
        uint256 rawQuote = q.balanceOf(pairAddr);
        uint256 burnAmount = rawQuote - fees + 1;
        q.burn(pairAddr, burnAmount);

        expectRevertMsg("VAULT_DRIFT");
        p.sync();
    }
}
