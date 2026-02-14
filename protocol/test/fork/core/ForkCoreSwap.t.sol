pragma solidity =0.5.16;

import "../helpers/ForkFixture.sol";

contract ForkCoreSwapTest is ForkFixture {
    function setUp() public {
        _setUpFork();
    }

    function testFork_swap_buy_preDeduction_taxAccrues() public onlyFork {
        (uint256 rq, uint256 rb) = _reservesQuoteBase();
        uint256 rawIn = 10 ether;
        uint256 tax = rawIn * pair.buyTaxBps() / BPS;
        uint256 effIn = rawIn - tax;
        uint256 out = _getAmountOut(effIn, rq, rb);

        uint256 beforeVault = pair.accumulatedQuoteTax();
        _buy(rawIn, out, TRADER);
        uint256 afterVault = pair.accumulatedQuoteTax();
        assertEq(afterVault - beforeVault, tax, "buy tax accrual mismatch");
    }

    function testFork_swap_sell_reverseCeil_taxAccrues() public onlyFork {
        (uint256 rq, uint256 rb) = _reservesQuoteBase();
        uint256 netOut = 1 ether;
        uint256 grossOut = _ceilDiv(netOut * BPS, BPS - pair.sellTaxBps());
        uint256 taxOut = grossOut - netOut;
        uint256 inBase = _getAmountIn(grossOut, rb, rq);

        uint256 beforeVault = pair.accumulatedQuoteTax();
        _sell(inBase, netOut, TRADER);
        uint256 afterVault = pair.accumulatedQuoteTax();
        assertEq(afterVault - beforeVault, taxOut, "sell tax accrual mismatch");
    }

    function testFork_swap_kInvariant_afterTaxedSwap() public onlyFork {
        (uint256 rq0, uint256 rb0) = _reservesQuoteBase();
        uint256 k0 = rq0 * rb0;

        uint256 rawIn = 15 ether;
        uint256 effIn = rawIn - (rawIn * pair.buyTaxBps() / BPS);
        uint256 out = _getAmountOut(effIn, rq0, rb0);
        _buy(rawIn, out, TRADER);

        (uint256 rq1, uint256 rb1) = _reservesQuoteBase();
        uint256 k1 = rq1 * rb1;
        assertGe(k1, k0, "k decreased");
    }

    function testFork_swap_singleSideOnly_revert() public onlyFork {
        vm.prank(TRADER);
        expectRevertMsg("SINGLE_SIDE_ONLY");
        pair.swap(1, 1, TRADER, new bytes(0));
    }

    function testFork_swap_invalidTo_revert() public onlyFork {
        address t0 = pair.token0();
        vm.prank(TRADER);
        expectRevertMsg("INVALID_TO");
        pair.swap(0, 1, t0, new bytes(0));
    }

    function testFork_swap_zeroInput_revert() public onlyFork {
        bool isQ0 = _isQuote0();
        vm.prank(TRADER);
        expectRevertMsg("INSUFFICIENT_INPUT");
        if (isQ0) {
            pair.swap(0, 1, TRADER, new bytes(0));
        } else {
            pair.swap(1, 0, TRADER, new bytes(0));
        }
    }

    function testFork_swap_insufficientLiquidity_revert() public onlyFork {
        (uint112 r0,,) = pair.getReserves();
        vm.prank(TRADER);
        expectRevertMsg("INSUFFICIENT_LIQUIDITY");
        pair.swap(uint256(r0), 0, TRADER, new bytes(0));
    }

    function testFork_swap_event_effIn_matchesReserveDelta() public onlyFork {
        (uint256 rq0, uint256 rb0) = _reservesQuoteBase();
        uint256 rawIn = 12 ether;
        uint256 tax = rawIn * pair.buyTaxBps() / BPS;
        uint256 effIn = rawIn - tax;
        uint256 out = _getAmountOut(effIn, rq0, rb0);
        _buy(rawIn, out, TRADER);
        (uint256 rq1, uint256 rb1) = _reservesQuoteBase();
        assertEq(rq1 - rq0, effIn, "effective quote in mismatch");
        assertEq(rb0 - rb1, out, "base out mismatch");
    }

    function testFork_swap_vaultOverflow_guard() public onlyFork {
        (uint256 rawQuote,) = _rawQuoteBase();
        if (rawQuote < uint256(uint96(-1)) - 1) {
            return;
        }
        _setVault(uint96(-1) - 1);
        (uint256 rq, uint256 rb) = _reservesQuoteBase();
        uint256 rawIn = 2 ether;
        uint256 effIn = rawIn - (rawIn * pair.buyTaxBps() / BPS);
        uint256 out = _getAmountOut(effIn, rq, rb);
        _fundQuote(TRADER, rawIn);
        vm.prank(TRADER);
        _safeTokenTransfer(monadQuoteToken, address(pair), rawIn);
        expectRevertMsg("VAULT_OVERFLOW");
        vm.prank(TRADER);
        if (_isQuote0()) {
            pair.swap(0, out, TRADER, new bytes(0));
        } else {
            pair.swap(out, 0, TRADER, new bytes(0));
        }
    }

    function testFork_swap_vaultDrift_guard() public onlyFork {
        (uint256 rawQuote,) = _rawQuoteBase();
        _setVault(uint96(rawQuote + 1));
        bool isQ0 = _isQuote0();
        _fundBase(TRADER, 1 ether);
        vm.prank(TRADER);
        _safeTokenTransfer(monadBaseToken, address(pair), 1 ether);
        vm.prank(TRADER);
        expectRevertMsg("VAULT_DRIFT");
        if (isQ0) {
            pair.swap(0, 1, TRADER, new bytes(0));
        } else {
            pair.swap(1, 0, TRADER, new bytes(0));
        }
    }
}
