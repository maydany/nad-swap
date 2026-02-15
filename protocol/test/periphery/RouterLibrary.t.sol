pragma solidity =0.5.16;

import "../../src/core/NadSwapV2Factory.sol";
import "../../src/core/NadSwapV2Pair.sol";
import "../../src/periphery/NadSwapV2Router02.sol";
import "../../src/periphery/libraries/NadSwapV2Library.sol";
import "../helpers/MockERC20.sol";
import "../helpers/MockWETH.sol";
import "../helpers/TestBase.sol";

contract LibraryHarness {
    function pairForExt(address factory, address tokenA, address tokenB) external view returns (address) {
        return UniswapV2Library.pairFor(factory, tokenA, tokenB);
    }

    function getAmountOutExt(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) external pure returns (uint256) {
        return UniswapV2Library.getAmountOut(amountIn, reserveIn, reserveOut);
    }
}

contract RouterLibraryTest is TestBase {
    uint256 private constant BPS = 10_000;

    UniswapV2Factory internal factory;
    UniswapV2Router02 internal router;
    UniswapV2Pair internal pair;
    LibraryHarness internal harness;
    MockERC20 internal quote;
    MockERC20 internal base;
    MockWETH internal weth;

    address internal constant PAIR_ADMIN = address(0x200);
    address internal constant COLLECTOR = address(0x300);
    address internal constant LP = address(0x111);

    function setUp() public {
        quote = new MockERC20("Quote", "QT", 18);
        base = new MockERC20("Base", "BS", 18);
        weth = new MockWETH();

        factory = new UniswapV2Factory(PAIR_ADMIN);
        router = new UniswapV2Router02(address(factory), address(weth));
        harness = new LibraryHarness();

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

    function test_pairFor_usesFactoryGetPair() public {
        address resolved = harness.pairForExt(address(factory), address(quote), address(base));
        assertEq(resolved, address(pair), "pairFor mismatch");
    }

    function test_library_lpFee_998() public {
        uint256 out = harness.getAmountOutExt(1000, 1_000_000, 1_000_000);
        uint256 expected = (uint256(1000) * 998 * 1_000_000) / (uint256(1_000_000) * 1000 + 1000 * 998);
        assertEq(out, expected, "lp fee mismatch");
    }

    function test_router_noPairRevert() public {
        MockERC20 x = new MockERC20("X", "X", 18);
        MockERC20 y = new MockERC20("Y", "Y", 18);

        vm.prank(PAIR_ADMIN);
        factory.setQuoteToken(address(x), true);

        x.mint(address(this), 1000 ether);
        y.mint(address(this), 1000 ether);
        x.approve(address(router), uint256(-1));
        y.approve(address(router), uint256(-1));

        expectRevertMsg("PAIR_NOT_CREATED");
        router.addLiquidity(address(x), address(y), 100 ether, 100 ether, 0, 0, address(this), block.timestamp + 1);
    }

    function test_router_supportingFOT_notSupported() public {
        address[] memory path = new address[](2);
        path[0] = address(quote);
        path[1] = address(base);

        expectRevertMsg("FOT_NOT_SUPPORTED");
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            1 ether,
            0,
            path,
            address(this),
            block.timestamp + 1
        );
    }

    function test_router_supportingFOT_notSupported_exactETHForTokens() public {
        address[] memory path = new address[](2);
        path[0] = address(weth);
        path[1] = address(base);

        expectRevertMsg("FOT_NOT_SUPPORTED");
        router.swapExactETHForTokensSupportingFeeOnTransferTokens.value(1 ether)(
            0,
            path,
            address(this),
            block.timestamp + 1
        );
    }

    function test_router_supportingFOT_notSupported_exactTokensForETH() public {
        address[] memory path = new address[](2);
        path[0] = address(base);
        path[1] = address(weth);

        expectRevertMsg("FOT_NOT_SUPPORTED");
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            1 ether,
            0,
            path,
            address(this),
            block.timestamp + 1
        );
    }

    function test_router_supportingFOT_notSupported_removeLiquidityETH() public {
        expectRevertMsg("FOT_NOT_SUPPORTED");
        router.removeLiquidityETHSupportingFeeOnTransferTokens(
            address(base),
            0,
            0,
            0,
            address(this),
            block.timestamp + 1
        );
    }

    function test_router_supportingFOT_notSupported_removeLiquidityETHWithPermit() public {
        expectRevertMsg("FOT_NOT_SUPPORTED");
        router.removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
            address(base),
            0,
            0,
            0,
            address(this),
            block.timestamp + 1,
            false,
            0,
            bytes32(0),
            bytes32(0)
        );
    }

    function test_sellExactIn_safeMargin_avoidsLiquidityEdge() public {
        address[] memory path = new address[](2);
        path[0] = address(base);
        path[1] = address(quote);

        uint256[] memory amounts = router.getAmountsOut(1000 ether, path);
        (uint112 r0, uint112 r1,) = pair.getReserves();
        uint256 reserveBase = pair.quoteToken() == pair.token0() ? uint256(r1) : uint256(r0);
        uint256 reserveQuote = pair.quoteToken() == pair.token0() ? uint256(r0) : uint256(r1);

        uint256 amountIn = 1000 ether;
        uint256 grossOut = (amountIn * 998 * reserveQuote) / (reserveBase * 1000 + amountIn * 998);
        uint256 expectedSafe = (grossOut * (BPS - pair.sellTaxBps())) / BPS;
        assertEq(amounts[1], expectedSafe, "sell exact-in quote mismatch");

        base.mint(address(this), amountIn);
        base.approve(address(router), uint256(-1));
        uint256 quoteBefore = quote.balanceOf(address(this));
        router.swapExactTokensForTokens(amountIn, expectedSafe, path, address(this), block.timestamp + 1);
        uint256 quoteReceived = quote.balanceOf(address(this)) - quoteBefore;
        assertEq(quoteReceived, expectedSafe, "sell exact-in quote not executable");
    }
}
