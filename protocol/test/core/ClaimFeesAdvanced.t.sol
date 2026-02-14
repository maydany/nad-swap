pragma solidity =0.5.16;

import "./../helpers/PairFixture.sol";
import "./../helpers/MockReentrantCollector.sol";
import "./../helpers/MockNonStandardERC20.sol";

contract ClaimFeesAdvancedTest is PairFixture {
    MockReentrantCollector internal reentrantCollector;

    function setUp() public {
        _setUpPair(300, 500);
        reentrantCollector = new MockReentrantCollector();
    }

    function _accrueVault() internal returns (uint256 accrued) {
        (uint256 rq, uint256 rb) = _reservesQuoteBase();
        uint256 rawIn = 1200 ether;
        uint256 effIn = rawIn - (rawIn * pair.buyTaxBps() / BPS);
        uint256 baseOut = _getAmountOut(effIn, rq, rb);
        uint256 beforeVault = pair.accumulatedQuoteFees();
        _buy(rawIn, baseOut, TRADER);
        accrued = pair.accumulatedQuoteFees() - beforeVault;
    }

    function test_claim_CEI_order() public {
        uint256 fees = _accrueVault();
        uint256 beforeRecipient = _quoteBalance(FEE_RECIPIENT);

        vm.prank(COLLECTOR);
        pair.claimQuoteFees(FEE_RECIPIENT);

        uint256 afterRecipient = _quoteBalance(FEE_RECIPIENT);
        assertEq(pair.accumulatedQuoteFees(), 0, "vault not reset");
        assertEq(afterRecipient - beforeRecipient, fees, "claim transfer mismatch");
    }

    function test_claim_reentrancy_blocked() public {
        _accrueVault();

        uint16 buyTax = pair.buyTaxBps();
        uint16 sellTax = pair.sellTaxBps();
        vm.prank(TAX_ADMIN);
        factory.setTaxConfig(address(pair), buyTax, sellTax, address(reentrantCollector));

        uint256 netQuoteOut = 10 ether;
        uint256 grossQuoteOut = _ceilDiv(netQuoteOut * BPS, BPS - pair.sellTaxBps());
        uint256 repayAmount = _ceilDiv(grossQuoteOut * 1000, 998);
        _mintToken(quoteTokenAddr, address(reentrantCollector), repayAmount);
        reentrantCollector.setPair(address(pair));
        reentrantCollector.setRepay(quoteTokenAddr, repayAmount);

        if (_isQuote0()) {
            pair.swap(netQuoteOut, 0, address(reentrantCollector), hex"01");
        } else {
            pair.swap(0, netQuoteOut, address(reentrantCollector), hex"01");
        }

        assertTrue(reentrantCollector.callbackEntered(), "callback not entered");
        assertTrue(!reentrantCollector.claimCallSucceeded(), "reentrant claim unexpectedly succeeded");
    }

    function test_claim_selfTransfer_revert() public {
        _accrueVault();
        vm.prank(COLLECTOR);
        expectRevertMsg("INVALID_TO");
        pair.claimQuoteFees(address(pair));
    }

    function test_claim_vaultDrift_revert() public {
        _accrueVault();
        (uint256 rawQuote,) = _rawQuoteBase();
        _setVault(uint96(rawQuote + 1));

        vm.prank(COLLECTOR);
        expectRevertMsg("VAULT_DRIFT");
        pair.claimQuoteFees(FEE_RECIPIENT);
    }

    function test_safeTransfer_nonStandard() public {
        MockNonStandardERC20 q = new MockNonStandardERC20("USDT-Like", "USDTL", 18);
        MockERC20 b = new MockERC20("Base", "BASE", 18);
        UniswapV2Factory f = new UniswapV2Factory(FEE_TO_SETTER, TAX_ADMIN);

        vm.prank(FEE_TO_SETTER);
        f.setQuoteToken(address(q), true);
        vm.prank(FEE_TO_SETTER);
        f.setBaseTokenSupported(address(b), true);
        vm.prank(TAX_ADMIN);
        address pairAddr = f.createPair(address(q), address(b), 300, 500, COLLECTOR);
        UniswapV2Pair p = UniswapV2Pair(pairAddr);

        _mintToken(address(q), LP, 1_000_000 ether);
        b.mint(LP, 1_000_000 ether);
        vm.prank(LP);
        _safeTokenTransfer(address(q), pairAddr, 1_000_000 ether);
        vm.prank(LP);
        b.transfer(pairAddr, 1_000_000 ether);
        vm.prank(LP);
        p.mint(LP);

        (uint112 r0, uint112 r1,) = p.getReserves();
        uint256 rq = p.quoteToken() == p.token0() ? uint256(r0) : uint256(r1);
        uint256 rb = p.quoteToken() == p.token0() ? uint256(r1) : uint256(r0);
        uint256 rawIn = 1_000 ether;
        uint256 effIn = rawIn - (rawIn * p.buyTaxBps() / BPS);
        uint256 baseOut = _getAmountOut(effIn, rq, rb);

        _mintToken(address(q), TRADER, rawIn);
        vm.prank(TRADER);
        _safeTokenTransfer(address(q), pairAddr, rawIn);
        if (p.quoteToken() == p.token0()) {
            vm.prank(TRADER);
            p.swap(0, baseOut, TRADER, new bytes(0));
        } else {
            vm.prank(TRADER);
            p.swap(baseOut, 0, TRADER, new bytes(0));
        }

        uint256 beforeBal = q.balanceOf(FEE_RECIPIENT);
        vm.prank(COLLECTOR);
        p.claimQuoteFees(FEE_RECIPIENT);
        uint256 afterBal = q.balanceOf(FEE_RECIPIENT);

        assertGt(afterBal, beforeBal, "claim did not transfer non-standard token");
        assertEq(p.accumulatedQuoteFees(), 0, "vault not reset");
    }
}
