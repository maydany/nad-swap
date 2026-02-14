pragma solidity =0.5.16;

import "../helpers/ForkFixture.sol";

contract ForkCoreLifecycleTest is ForkFixture {
    address internal constant LP2 = address(0x555);

    function setUp() public {
        _setUpFork();
    }

    function _accrueVault() internal {
        (uint256 rq, uint256 rb) = _reservesQuoteBase();
        uint256 rawIn = 8 ether;
        uint256 effIn = rawIn - (rawIn * pair.buyTaxBps() / BPS);
        uint256 out = _getAmountOut(effIn, rq, rb);
        _buy(rawIn, out, TRADER);
    }

    function testFork_mint_excludesVault() public onlyFork {
        _accrueVault();
        (uint256 rq0, uint256 rb0) = _reservesQuoteBase();
        uint256 q = 10 ether;
        uint256 b = 10 ether;
        _fundQuote(LP2, q);
        _fundBase(LP2, b);
        vm.prank(LP2);
        _safeTokenTransfer(monadQuoteToken, address(pair), q);
        vm.prank(LP2);
        _safeTokenTransfer(monadBaseToken, address(pair), b);
        vm.prank(LP2);
        pair.mint(LP2);
        (uint256 rq1, uint256 rb1) = _reservesQuoteBase();
        assertEq(rq1 - rq0, q, "mint quote delta mismatch");
        assertEq(rb1 - rb0, b, "mint base delta mismatch");
    }

    function testFork_burn_excludesVault() public onlyFork {
        _accrueVault();
        (uint256 rq0, uint256 rb0) = _reservesQuoteBase();
        uint256 liq = pair.balanceOf(LP) / 20;
        uint256 ts = pair.totalSupply();
        uint256 wantQ = liq * rq0 / ts;
        uint256 wantB = liq * rb0 / ts;
        uint256 q0 = _quoteBalance(LP);
        uint256 b0 = _baseBalance(LP);
        vm.prank(LP);
        pair.transfer(address(pair), liq);
        vm.prank(LP);
        pair.burn(LP);
        assertEq(_quoteBalance(LP) - q0, wantQ, "burn quote mismatch");
        assertEq(_baseBalance(LP) - b0, wantB, "burn base mismatch");
    }

    function testFork_mint_afterSwap_vaultIntact() public onlyFork {
        _accrueVault();
        uint256 v0 = pair.accumulatedQuoteFees();
        _fundQuote(LP2, 5 ether);
        _fundBase(LP2, 5 ether);
        vm.prank(LP2);
        _safeTokenTransfer(monadQuoteToken, address(pair), 5 ether);
        vm.prank(LP2);
        _safeTokenTransfer(monadBaseToken, address(pair), 5 ether);
        vm.prank(LP2);
        pair.mint(LP2);
        assertEq(pair.accumulatedQuoteFees(), v0, "vault changed on mint");
    }

    function testFork_burn_afterSwap_vaultIntact() public onlyFork {
        _accrueVault();
        uint256 v0 = pair.accumulatedQuoteFees();
        uint256 liq = pair.balanceOf(LP) / 50;
        vm.prank(LP);
        pair.transfer(address(pair), liq);
        vm.prank(LP);
        pair.burn(LP);
        assertEq(pair.accumulatedQuoteFees(), v0, "vault changed on burn");
    }

    function testFork_sync_withVault_usesEffective() public onlyFork {
        _accrueVault();
        _fundQuote(LP2, 1 ether);
        vm.prank(LP2);
        _safeTokenTransfer(monadQuoteToken, address(pair), 1 ether);
        pair.sync();
        (uint256 reserveQuote,) = _reservesQuoteBase();
        (uint256 rawQuote,) = _rawQuoteBase();
        assertEq(reserveQuote, rawQuote - pair.accumulatedQuoteFees(), "sync effective mismatch");
    }

    function testFork_sync_afterClaim_reserveEqualsRaw() public onlyFork {
        _accrueVault();
        vm.prank(COLLECTOR);
        pair.claimQuoteFees(address(0x999));
        pair.sync();
        (uint256 reserveQuote,) = _reservesQuoteBase();
        (uint256 rawQuote,) = _rawQuoteBase();
        assertEq(pair.accumulatedQuoteFees(), 0, "vault not zero");
        assertEq(reserveQuote, rawQuote, "reserve/raw mismatch");
    }

    function testFork_skim_excessDust_transfer() public onlyFork {
        _fundQuote(LP2, 1 ether);
        _fundBase(LP2, 1 ether);
        vm.prank(LP2);
        _safeTokenTransfer(monadQuoteToken, address(pair), 1 ether);
        vm.prank(LP2);
        _safeTokenTransfer(monadBaseToken, address(pair), 1 ether);
        uint256 q0 = _quoteBalance(address(0x777));
        uint256 b0 = _baseBalance(address(0x777));
        pair.skim(address(0x777));
        assertGt(_quoteBalance(address(0x777)) - q0, 0, "no quote dust");
        assertGt(_baseBalance(address(0x777)) - b0, 0, "no base dust");
    }

    function testFork_firstDeposit_minimumLiquidity() public onlyFork {
        UniswapV2Factory f = new UniswapV2Factory(PAIR_ADMIN);
        vm.prank(PAIR_ADMIN);
        f.setQuoteToken(monadQuoteToken, true);
        vm.prank(PAIR_ADMIN);
        f.setBaseTokenSupported(monadBaseToken, true);
        vm.prank(PAIR_ADMIN);
        address pairAddr = f.createPair(monadQuoteToken, monadBaseToken, 300, 500, COLLECTOR);
        UniswapV2Pair p = UniswapV2Pair(pairAddr);
        _fundQuote(LP2, 3 ether);
        _fundBase(LP2, 3 ether);
        vm.prank(LP2);
        _safeTokenTransfer(monadQuoteToken, pairAddr, 3 ether);
        vm.prank(LP2);
        _safeTokenTransfer(monadBaseToken, pairAddr, 3 ether);
        vm.prank(LP2);
        p.mint(LP2);
        assertEq(p.balanceOf(address(0)), p.MINIMUM_LIQUIDITY(), "minimum liquidity not burned");
    }
}
