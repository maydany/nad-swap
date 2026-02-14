pragma solidity =0.5.16;

import "./../helpers/PairFixture.sol";
import "./../helpers/MockFlashCallee.sol";

contract PairFlashQuoteTest is PairFixture {
    MockFlashCallee internal flashCallee;

    function setUp() public {
        _setUpPair(300, 500);
        flashCallee = new MockFlashCallee();
    }

    function _runQuoteFlash(uint256 netQuoteOut, uint256 repayExtra)
        internal
        returns (uint256 grossQuoteOut, uint256 quoteTaxOut, uint256 repayAmount)
    {
        grossQuoteOut = _ceilDiv(netQuoteOut * BPS, BPS - pair.sellTaxBps());
        quoteTaxOut = grossQuoteOut - netQuoteOut;
        repayAmount = _ceilDiv(grossQuoteOut * 1000, 998) + repayExtra;

        _mintToken(quoteTokenAddr, address(flashCallee), repayAmount);
        if (_isQuote0()) {
            flashCallee.execute(address(pair), netQuoteOut, 0, quoteTokenAddr, repayAmount);
        } else {
            flashCallee.execute(address(pair), 0, netQuoteOut, quoteTokenAddr, repayAmount);
        }
    }

    function test_quoteFlash_sameToken_sellTax_applies() public {
        uint256 vaultBefore = pair.accumulatedQuoteTax();
        (, uint256 quoteTaxOut,) = _runQuoteFlash(100 ether, 0);
        uint256 vaultAfter = pair.accumulatedQuoteTax();

        assertEq(vaultAfter - vaultBefore, quoteTaxOut, "sell tax not accrued on quote flash");
        assertGt(quoteTaxOut, 0, "expected positive sell tax");
    }

    function test_quoteFlash_sameToken_noBypass_coreTax() public {
        uint256 vaultBefore = pair.accumulatedQuoteTax();
        (, uint256 quoteTaxOut,) = _runQuoteFlash(50 ether, 10 ether);
        uint256 vaultAfter = pair.accumulatedQuoteTax();

        assertEq(vaultAfter - vaultBefore, quoteTaxOut, "flash callback bypassed core tax");
    }

    function test_quoteFlash_sameToken_buyTax_notApplied_when_noBaseOut() public {
        uint256 vaultBefore = pair.accumulatedQuoteTax();
        (, uint256 quoteTaxOut,) = _runQuoteFlash(75 ether, 1 ether);
        uint256 vaultAfter = pair.accumulatedQuoteTax();

        assertEq(vaultAfter - vaultBefore, quoteTaxOut, "buy tax should not apply on no-base-out flash");
    }

    function test_quoteFlash_sameToken_kInvariant_holds_after_tax() public {
        (uint256 rqBefore, uint256 rbBefore) = _reservesQuoteBase();
        uint256 kBefore = rqBefore * rbBefore;
        _runQuoteFlash(120 ether, 0);
        (uint256 rqAfter, uint256 rbAfter) = _reservesQuoteBase();
        uint256 kAfter = rqAfter * rbAfter;

        assertGe(kAfter, kBefore, "K invariant failed after quote flash");
    }
}
