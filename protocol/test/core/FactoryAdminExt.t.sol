pragma solidity =0.5.16;

import "./../helpers/PairFixture.sol";
import "./../helpers/MockERC20.sol";
import "../../src/core/UniswapV2Pair.sol";

contract FactoryAdminExtTest is PairFixture {
    MockERC20 internal alt;

    function setUp() public {
        _setUpPair(300, 500);
        alt = new MockERC20("Alt", "ALT", 18);
    }

    function _reservesQuoteBaseFor(UniswapV2Pair p) internal view returns (uint256 rq, uint256 rb) {
        (uint112 r0, uint112 r1,) = p.getReserves();
        if (p.quoteToken() == p.token0()) {
            rq = uint256(r0);
            rb = uint256(r1);
        } else {
            rq = uint256(r1);
            rb = uint256(r0);
        }
    }

    function test_createPair_frontRunBlocked() public {
        vm.prank(FEE_TO_SETTER);
        factory.setBaseTokenSupported(address(alt), true);

        vm.prank(OTHER);
        expectRevertMsg("FORBIDDEN");
        factory.createPair(quoteTokenAddr, address(alt), 300, 500, COLLECTOR);
    }

    function test_factory_invalidPair_revert() public {
        vm.prank(PAIR_ADMIN);
        expectRevertMsg("INVALID_PAIR");
        factory.setTaxConfig(address(0xdead), 100, 100, COLLECTOR);
    }

    function test_setQuoteToken_nonFeeToSetter_revert() public {
        vm.prank(OTHER);
        expectRevertMsg("FORBIDDEN");
        factory.setQuoteToken(address(alt), true);
    }

    function test_setBaseTokenSupported_zeroAddr_revert() public {
        vm.prank(FEE_TO_SETTER);
        expectRevertMsg("ZERO_ADDRESS");
        factory.setBaseTokenSupported(address(0), true);
    }

    function test_initialize_reentryBlocked() public {
        address t0 = pair.token0();
        address t1 = pair.token1();
        address qt = pair.quoteToken();
        uint16 buyTax = pair.buyTaxBps();
        uint16 sellTax = pair.sellTaxBps();
        expectRevertMsg("ALREADY_INITIALIZED");
        vm.prank(address(factory));
        pair.initialize(t0, t1, qt, buyTax, sellTax, COLLECTOR);
    }

    function test_initialize_nonFactory_revert() public {
        UniswapV2Pair p = new UniswapV2Pair();
        vm.prank(OTHER);
        expectRevertMsg("FORBIDDEN");
        p.initialize(address(quote), address(base), address(quote), 100, 100, COLLECTOR);
    }

    function test_initialize_zeroCollector() public {
        UniswapV2Pair p = new UniswapV2Pair();
        expectRevertMsg("ZERO_COLLECTOR");
        p.initialize(address(quote), address(base), address(quote), 100, 100, address(0));
    }

    function test_initialize_invalidQuote() public {
        UniswapV2Pair p = new UniswapV2Pair();
        expectRevertMsg("INVALID_QUOTE");
        p.initialize(address(quote), address(base), address(alt), 100, 100, COLLECTOR);
    }

    function test_initialize_taxTooHigh_revert() public {
        UniswapV2Pair p = new UniswapV2Pair();
        expectRevertMsg("TAX_TOO_HIGH");
        p.initialize(address(quote), address(base), address(quote), 2001, 10, COLLECTOR);
    }

    function test_initialize_sellTax100pct_revert() public {
        UniswapV2Pair p = new UniswapV2Pair();
        expectRevertMsg("TAX_TOO_HIGH");
        p.initialize(address(quote), address(base), address(quote), 0, 10_000, COLLECTOR);
    }

    function test_atomicInit_noTaxFreeWindow() public {
        vm.prank(FEE_TO_SETTER);
        factory.setBaseTokenSupported(address(alt), true);

        vm.prank(PAIR_ADMIN);
        address pairAddr = factory.createPair(quoteTokenAddr, address(alt), 300, 500, COLLECTOR);
        UniswapV2Pair p = UniswapV2Pair(pairAddr);

        alt.mint(LP, 1_000_000 ether);
        quote.mint(LP, 1_000_000 ether);
        vm.prank(LP);
        quote.transfer(pairAddr, 1_000_000 ether);
        vm.prank(LP);
        alt.transfer(pairAddr, 1_000_000 ether);
        vm.prank(LP);
        p.mint(LP);

        (uint256 rq, uint256 rb) = _reservesQuoteBaseFor(p);
        uint256 rawIn = 1000 ether;
        uint256 effIn = rawIn - (rawIn * p.buyTaxBps() / BPS);
        uint256 baseOut = _getAmountOut(effIn, rq, rb);

        quote.mint(TRADER, rawIn);
        vm.prank(TRADER);
        quote.transfer(pairAddr, rawIn);
        if (p.quoteToken() == p.token0()) {
            vm.prank(TRADER);
            p.swap(0, baseOut, TRADER, new bytes(0));
        } else {
            vm.prank(TRADER);
            p.swap(baseOut, 0, TRADER, new bytes(0));
        }

        assertGt(p.accumulatedQuoteFees(), 0, "first swap was tax-free");
    }

    function test_pairAdmin_immutable() public {
        address beforeAdmin = factory.pairAdmin();
        vm.prank(FEE_TO_SETTER);
        factory.setFeeToSetter(OTHER);
        assertEq(factory.pairAdmin(), beforeAdmin, "pairAdmin changed unexpectedly");

        (bool success,) = address(factory).call(abi.encodeWithSignature("setPairAdmin(address)", OTHER));
        assertTrue(!success, "setPairAdmin path should not exist");
    }

    function test_setTaxConfig_alwaysMutable() public {
        vm.prank(PAIR_ADMIN);
        factory.setTaxConfig(address(pair), 100, 200, address(0xabc));
        assertEq(uint256(pair.buyTaxBps()), 100, "buy tax not updated #1");
        assertEq(uint256(pair.sellTaxBps()), 200, "sell tax not updated #1");
        assertEq(pair.feeCollector(), address(0xabc), "collector not updated #1");

        vm.prank(PAIR_ADMIN);
        factory.setTaxConfig(address(pair), 300, 400, address(0xdef));
        assertEq(uint256(pair.buyTaxBps()), 300, "buy tax not updated #2");
        assertEq(uint256(pair.sellTaxBps()), 400, "sell tax not updated #2");
        assertEq(pair.feeCollector(), address(0xdef), "collector not updated #2");
    }

    function test_setTaxConfig_nonFactory_revert() public {
        expectRevertMsg("FORBIDDEN");
        pair.setTaxConfig(1, 1, COLLECTOR);
    }

    function test_setTaxConfig_sellTax100pct_revert() public {
        vm.prank(PAIR_ADMIN);
        expectRevertMsg("TAX_TOO_HIGH");
        factory.setTaxConfig(address(pair), 0, 10_000, COLLECTOR);
    }

    function test_setTaxConfig_zeroCollector() public {
        vm.prank(PAIR_ADMIN);
        expectRevertMsg("ZERO_COLLECTOR");
        factory.setTaxConfig(address(pair), 10, 10, address(0));
    }
}
