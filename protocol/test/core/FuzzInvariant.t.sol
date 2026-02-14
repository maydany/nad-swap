pragma solidity =0.5.16;

import "../../src/core/NadSwapV2Factory.sol";
import "../../src/core/NadSwapV2Pair.sol";
import "../helpers/MockERC20.sol";
import "../helpers/TestBase.sol";

contract FuzzInvariantTest is TestBase {
    uint256 private constant BPS = 10_000;

    UniswapV2Factory internal factory;
    UniswapV2Pair internal pair;
    MockERC20 internal quote;
    MockERC20 internal base;

    address internal constant PAIR_ADMIN = address(0x200);
    address internal constant COLLECTOR = address(0x300);
    address internal constant LP = address(0x111);
    address internal constant TRADER = address(0x222);

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

    function testFuzz_buyTax_floor_matchesPair(uint96 rawIn) public {
        vm.assume(rawIn > 0);
        vm.assume(rawIn < 5_000 ether);

        (uint256 rq, uint256 rb) = _reservesQuoteBase();
        uint256 tax = uint256(rawIn) * pair.buyTaxBps() / BPS;
        uint256 effIn = uint256(rawIn) - tax;
        uint256 baseOut = _getAmountOut(effIn, rq, rb);
        vm.assume(baseOut > 0);

        uint256 vaultBefore = pair.accumulatedQuoteFees();

        quote.mint(TRADER, rawIn);
        vm.prank(TRADER);
        quote.transfer(address(pair), rawIn);

        if (_isQuote0()) {
            vm.prank(TRADER);
            pair.swap(0, baseOut, TRADER, new bytes(0));
        } else {
            vm.prank(TRADER);
            pair.swap(baseOut, 0, TRADER, new bytes(0));
        }

        uint256 vaultAfter = pair.accumulatedQuoteFees();
        assertEq(vaultAfter - vaultBefore, tax, "fuzz tax mismatch");
    }

    function testInvariant_rawQuote_equals_reservePlusVault_afterSync() public {
        quote.mint(address(pair), 123 ether);
        pair.sync();

        (uint112 r0, uint112 r1,) = pair.getReserves();
        uint256 rawQuote = quote.balanceOf(address(pair));
        uint256 reserveQuote = _isQuote0() ? uint256(r0) : uint256(r1);

        assertEq(rawQuote, reserveQuote + pair.accumulatedQuoteFees(), "accounting invariant mismatch");
    }

    function testFuzz_sellTax_boundary_rounding(uint16 sellTaxBps, uint96 netQuoteOutSeed) public {
        vm.assume(sellTaxBps <= 2000);
        uint16 buyTax = pair.buyTaxBps();
        vm.prank(PAIR_ADMIN);
        factory.setTaxConfig(address(pair), buyTax, sellTaxBps, COLLECTOR);

        (uint256 rq, uint256 rb) = _reservesQuoteBase();
        uint256 cap = rq / 50;
        vm.assume(cap > 1);
        uint256 netQuoteOut = uint256(netQuoteOutSeed) % cap;
        vm.assume(netQuoteOut > 0);

        uint256 grossOut = _ceilDiv(netQuoteOut * BPS, BPS - sellTaxBps);
        vm.assume(grossOut < rq);
        uint256 baseIn = _getAmountIn(grossOut, rb, rq);

        uint256 beforeVault = pair.accumulatedQuoteFees();
        _sell(baseIn, netQuoteOut, TRADER);
        uint256 afterVault = pair.accumulatedQuoteFees();
        assertEq(afterVault - beforeVault, grossOut - netQuoteOut, "sell tax rounding mismatch");
    }

    function testFuzz_grossOut_lt_reserve(uint96 baseIn) public {
        vm.assume(baseIn > 0);
        vm.assume(baseIn < 10_000 ether);
        (uint256 rq, uint256 rb) = _reservesQuoteBase();
        uint256 grossOut = _getAmountOut(uint256(baseIn), rb, rq);
        assertTrue(grossOut < rq, "grossOut should stay below reserve");
    }

    function testInvariant_vault_monotonic_excluding_claim() public {
        (uint256 rq, uint256 rb) = _reservesQuoteBase();
        uint256 buyRawIn = 1_000 ether;
        uint256 buyEffIn = buyRawIn - (buyRawIn * pair.buyTaxBps() / BPS);
        uint256 buyBaseOut = _getAmountOut(buyEffIn, rq, rb);
        uint256 v0 = pair.accumulatedQuoteFees();
        _buy(buyRawIn, buyBaseOut, TRADER);
        uint256 v1 = pair.accumulatedQuoteFees();

        (rq, rb) = _reservesQuoteBase();
        uint256 netQuoteOut = 120 ether;
        uint256 grossQuoteOut = _ceilDiv(netQuoteOut * BPS, BPS - pair.sellTaxBps());
        uint256 sellBaseIn = _getAmountIn(grossQuoteOut, rb, rq);
        _sell(sellBaseIn, netQuoteOut, TRADER);
        uint256 v2 = pair.accumulatedQuoteFees();

        assertGe(v1, v0, "vault decreased after buy");
        assertGe(v2, v1, "vault decreased after sell");
    }

    function testInvariant_claim_after_rawQuote_equals_reserveQuote() public {
        (uint256 rq, uint256 rb) = _reservesQuoteBase();
        uint256 rawIn = 1_500 ether;
        uint256 effIn = rawIn - (rawIn * pair.buyTaxBps() / BPS);
        uint256 baseOut = _getAmountOut(effIn, rq, rb);
        _buy(rawIn, baseOut, TRADER);

        vm.prank(COLLECTOR);
        pair.claimQuoteFees(address(0x999));

        (uint112 r0, uint112 r1,) = pair.getReserves();
        uint256 reserveQuote = _isQuote0() ? uint256(r0) : uint256(r1);
        uint256 rawQuote = quote.balanceOf(address(pair));
        assertEq(rawQuote, reserveQuote, "raw quote should match reserve quote after claim");
    }

    function testInvariant_totalSupply_implies_positiveReserves() public {
        uint256 totalSupply = pair.totalSupply();
        if (totalSupply > 0) {
            (uint112 r0, uint112 r1,) = pair.getReserves();
            assertTrue(r0 > 0, "reserve0 should be positive when LP supply exists");
            assertTrue(r1 > 0, "reserve1 should be positive when LP supply exists");
        }
    }

    function testInvariant_factoryPairMappingConsistency() public {
        assertTrue(factory.isPair(address(pair)), "pair must be registered in isPair");
        assertEq(factory.getPair(address(quote), address(base)), address(pair), "forward pair mapping mismatch");
        assertEq(factory.getPair(address(base), address(quote)), address(pair), "reverse pair mapping mismatch");
    }
}
