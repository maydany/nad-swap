pragma solidity =0.5.16;

import "../helpers/ForkFixture.sol";
import "../../helpers/MockReentrantCollector.sol";

contract ForkCoreClaimTest is ForkFixture {
    MockReentrantCollector internal reentrantCollector;

    function setUp() public {
        _setUpFork();
        if (forkEnabled) {
            reentrantCollector = new MockReentrantCollector();
        }
    }

    function _accrueVault() internal {
        (uint256 rq, uint256 rb) = _reservesQuoteBase();
        uint256 rawIn = 10 ether;
        uint256 effIn = rawIn - (rawIn * pair.buyTaxBps() / BPS);
        uint256 out = _getAmountOut(effIn, rq, rb);
        _buy(rawIn, out, TRADER);
    }

    function testFork_claim_collectorOnly() public onlyFork {
        _accrueVault();
        vm.prank(TRADER);
        expectRevertMsg("FORBIDDEN");
        pair.claimQuoteFees(address(0x999));
    }

    function testFork_claim_zeroAddress_revert() public onlyFork {
        _accrueVault();
        vm.prank(COLLECTOR);
        expectRevertMsg("INVALID_TO");
        pair.claimQuoteFees(address(0));
    }

    function testFork_claim_self_revert() public onlyFork {
        _accrueVault();
        vm.prank(COLLECTOR);
        expectRevertMsg("INVALID_TO");
        pair.claimQuoteFees(address(pair));
    }

    function testFork_claim_noFees_revert() public onlyFork {
        vm.prank(COLLECTOR);
        expectRevertMsg("NO_FEES");
        pair.claimQuoteFees(address(0x999));
    }

    function testFork_claim_success_vaultReset_and_transfer() public onlyFork {
        _accrueVault();
        uint256 fees = pair.accumulatedQuoteFees();
        uint256 b0 = _quoteBalance(address(0x999));
        vm.prank(COLLECTOR);
        pair.claimQuoteFees(address(0x999));
        assertEq(pair.accumulatedQuoteFees(), 0, "vault not reset");
        assertEq(_quoteBalance(address(0x999)) - b0, fees, "claim transfer mismatch");
    }

    function testFork_claim_reentrancy_blocked() public onlyFork {
        _accrueVault();
        uint16 bt = pair.buyTaxBps();
        uint16 st = pair.sellTaxBps();
        vm.prank(TAX_ADMIN);
        factory.setTaxConfig(address(pair), bt, st, address(reentrantCollector));

        uint256 netQuoteOut = 1 ether;
        uint256 grossQuoteOut = _ceilDiv(netQuoteOut * BPS, BPS - pair.sellTaxBps());
        uint256 repay = _ceilDiv(grossQuoteOut * 1000, 998);
        _fundQuote(address(reentrantCollector), repay);
        reentrantCollector.setPair(address(pair));
        reentrantCollector.setRepay(monadQuoteToken, repay);

        // Fund base to send as input for the sell swap
        (uint256 rq, uint256 rb) = _reservesQuoteBase();
        uint256 baseIn = _getAmountIn(grossQuoteOut, rb, rq);
        _fundBase(address(this), baseIn);
        _safeTokenTransfer(monadBaseToken, address(pair), baseIn);

        if (_isQuote0()) {
            pair.swap(netQuoteOut, 0, address(reentrantCollector), hex"01");
        } else {
            pair.swap(0, netQuoteOut, address(reentrantCollector), hex"01");
        }
        assertTrue(reentrantCollector.callbackEntered(), "callback not entered");
        assertTrue(!reentrantCollector.claimCallSucceeded(), "reentrant claim succeeded");
    }

    function testFork_claim_vaultDrift_revert() public onlyFork {
        _accrueVault();
        (uint256 rawQuote,) = _rawQuoteBase();
        _setVault(uint96(rawQuote + 1));
        vm.prank(COLLECTOR);
        expectRevertMsg("VAULT_DRIFT");
        pair.claimQuoteFees(address(0x999));
    }
}
