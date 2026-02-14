pragma solidity =0.5.16;

import "../../src/core/UniswapV2Factory.sol";
import "../../src/core/UniswapV2Pair.sol";
import "../helpers/MockERC20.sol";
import "../helpers/TestBase.sol";

contract PairSwapTest is TestBase {
    uint256 private constant BPS = 10_000;

    UniswapV2Factory internal factory;
    UniswapV2Pair internal pair;
    MockERC20 internal quote;
    MockERC20 internal base;

    address internal constant PAIR_ADMIN = address(0x200);
    address internal constant COLLECTOR = address(0x300);
    address internal constant LP = address(0x111);
    address internal constant TRADER = address(0x222);
    address internal constant FEE_RECIPIENT = address(0x333);

    function setUp() public {
        quote = new MockERC20("Quote", "QT", 18);
        base = new MockERC20("Base", "BS", 18);

        factory = new UniswapV2Factory(PAIR_ADMIN);
        vm.prank(PAIR_ADMIN);
        factory.setQuoteToken(address(quote), true);

        vm.prank(PAIR_ADMIN);
        address pairAddr = factory.createPair(address(quote), address(base), 300, 500, COLLECTOR);
        pair = UniswapV2Pair(pairAddr);

        quote.mint(LP, 10_000_000 ether);
        base.mint(LP, 10_000_000 ether);
        vm.prank(LP);
        quote.transfer(address(pair), 1_000_000 ether);
        vm.prank(LP);
        base.transfer(address(pair), 1_000_000 ether);
        vm.prank(LP);
        pair.mint(LP);
    }

    function _isQuote0() internal view returns (bool) {
        return pair.quoteToken() == pair.token0();
    }

    function _reservesQuoteBase() internal view returns (uint256 rq, uint256 rb) {
        (uint112 r0, uint112 r1,) = pair.getReserves();
        if (_isQuote0()) {
            rq = uint256(r0);
            rb = uint256(r1);
        } else {
            rq = uint256(r1);
            rb = uint256(r0);
        }
    }

    function _rawQuoteBase() internal view returns (uint256 rawQuote, uint256 rawBase) {
        rawQuote = quote.balanceOf(address(pair));
        rawBase = base.balanceOf(address(pair));
    }

    function _getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) internal pure returns (uint256) {
        uint256 amountInWithFee = amountIn * 998;
        return (amountInWithFee * reserveOut) / (reserveIn * 1000 + amountInWithFee);
    }

    function _getAmountIn(uint256 amountOut, uint256 reserveIn, uint256 reserveOut) internal pure returns (uint256) {
        return (reserveIn * amountOut * 1000) / ((reserveOut - amountOut) * 998) + 1;
    }

    function _ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a + b - 1) / b;
    }

    function _buy(uint256 rawQuoteIn, uint256 baseOut, address trader) internal {
        quote.mint(trader, rawQuoteIn);
        vm.prank(trader);
        quote.transfer(address(pair), rawQuoteIn);

        if (_isQuote0()) {
            vm.prank(trader);
            pair.swap(0, baseOut, trader, new bytes(0));
        } else {
            vm.prank(trader);
            pair.swap(baseOut, 0, trader, new bytes(0));
        }
    }

    function _sell(uint256 baseIn, uint256 netQuoteOut, address trader) internal {
        base.mint(trader, baseIn);
        vm.prank(trader);
        base.transfer(address(pair), baseIn);

        if (_isQuote0()) {
            vm.prank(trader);
            pair.swap(netQuoteOut, 0, trader, new bytes(0));
        } else {
            vm.prank(trader);
            pair.swap(0, netQuoteOut, trader, new bytes(0));
        }
    }

    function test_buy_preDeduction_taxIn() public {
        (uint256 rq, uint256 rb) = _reservesQuoteBase();
        uint256 rawQuoteIn = 1000 ether;
        uint256 expectedTax = rawQuoteIn * 300 / BPS;
        uint256 effIn = rawQuoteIn - expectedTax;
        uint256 baseOut = _getAmountOut(effIn, rq, rb);

        uint256 beforeVault = uint256(pair.accumulatedQuoteFees());
        _buy(rawQuoteIn, baseOut, TRADER);
        uint256 afterVault = uint256(pair.accumulatedQuoteFees());

        assertEq(afterVault - beforeVault, expectedTax, "buy taxIn mismatch");
    }

    function test_sell_reverseMath_ceilGross() public {
        (uint256 rq, uint256 rb) = _reservesQuoteBase();
        uint256 netQuoteOut = 100 ether;
        uint256 grossQuoteOut = _ceilDiv(netQuoteOut * BPS, BPS - 500);
        uint256 expectedTaxOut = grossQuoteOut - netQuoteOut;
        uint256 baseIn = _getAmountIn(grossQuoteOut, rb, rq);

        uint256 beforeVault = uint256(pair.accumulatedQuoteFees());
        _sell(baseIn, netQuoteOut, TRADER);
        uint256 afterVault = uint256(pair.accumulatedQuoteFees());

        assertEq(afterVault - beforeVault, expectedTaxOut, "sell taxOut mismatch");
    }

    function test_swap_bothZeroOut_revert() public {
        vm.prank(TRADER);
        expectRevertMsg("INSUFFICIENT_OUTPUT");
        pair.swap(0, 0, TRADER, new bytes(0));
    }

    function test_singleSideOnly_revert() public {
        vm.prank(TRADER);
        expectRevertMsg("SINGLE_SIDE_ONLY");
        pair.swap(1, 1, TRADER, new bytes(0));
    }

    function test_swap_invalidTo_revert() public {
        address badTo = pair.token0();
        vm.prank(TRADER);
        expectRevertMsg("INVALID_TO");
        pair.swap(0, 1, badTo, new bytes(0));
    }

    function test_swap_zeroInput_revert() public {
        vm.prank(TRADER);
        expectRevertMsg("INSUFFICIENT_INPUT");
        pair.swap(0, 1 ether, TRADER, new bytes(0));
    }

    function test_claim_nonCollector_revert() public {
        vm.prank(TRADER);
        expectRevertMsg("FORBIDDEN");
        pair.claimQuoteFees(FEE_RECIPIENT);
    }

    function test_claim_noFees_revert() public {
        vm.prank(COLLECTOR);
        expectRevertMsg("NO_FEES");
        pair.claimQuoteFees(FEE_RECIPIENT);
    }

    function test_claim_zeroAddress_revert() public {
        (uint256 rq, uint256 rb) = _reservesQuoteBase();
        uint256 rawQuoteIn = 500 ether;
        uint256 baseOut = _getAmountOut(rawQuoteIn - (rawQuoteIn * 300 / BPS), rq, rb);
        _buy(rawQuoteIn, baseOut, TRADER);

        vm.prank(COLLECTOR);
        expectRevertMsg("INVALID_TO");
        pair.claimQuoteFees(address(0));
    }

    function test_claim_vaultReset_reserveSync() public {
        (uint256 rq, uint256 rb) = _reservesQuoteBase();
        uint256 rawQuoteIn = 700 ether;
        uint256 baseOut = _getAmountOut(rawQuoteIn - (rawQuoteIn * 300 / BPS), rq, rb);
        _buy(rawQuoteIn, baseOut, TRADER);

        uint256 fees = pair.accumulatedQuoteFees();
        assertGt(fees, 0, "fees not accrued");

        uint256 beforeBal = quote.balanceOf(FEE_RECIPIENT);
        vm.prank(COLLECTOR);
        pair.claimQuoteFees(FEE_RECIPIENT);

        (uint256 reserveQuote, uint256 reserveBase) = _reservesQuoteBase();
        (uint256 rawQuote, uint256 rawBase) = _rawQuoteBase();
        assertEq(pair.accumulatedQuoteFees(), 0, "vault not reset");
        assertEq(quote.balanceOf(FEE_RECIPIENT) - beforeBal, fees, "fee transfer mismatch");
        assertEq(reserveQuote, rawQuote, "quote reserve not synced to raw");
        assertEq(reserveBase, rawBase, "base reserve not synced to raw");
    }
}
