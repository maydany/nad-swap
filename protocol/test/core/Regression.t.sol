pragma solidity =0.5.16;

import "../../src/core/NadSwapV2Factory.sol";
import "../../src/core/NadSwapV2Pair.sol";
import "../../src/periphery/NadSwapV2Router02.sol";
import "../helpers/MockERC20.sol";
import "../helpers/MockWETH.sol";
import "../helpers/TestBase.sol";

contract RegressionTest is TestBase {
    UniswapV2Factory internal factory;
    UniswapV2Pair internal pair;
    UniswapV2Router02 internal router;
    MockERC20 internal quote;
    MockERC20 internal base;
    MockWETH internal weth;

    address internal constant PAIR_ADMIN = address(0x200);
    address internal constant COLLECTOR = address(0x300);
    address internal constant LP = address(0x111);
    address internal constant LP2 = address(0x112);
    address internal constant TRADER = address(0x222);

    function setUp() public {
        quote = new MockERC20("Quote", "QT", 18);
        base = new MockERC20("Base", "BS", 18);
        weth = new MockWETH();

        factory = new UniswapV2Factory(PAIR_ADMIN);
        router = new UniswapV2Router02(address(factory), address(weth));
        vm.prank(PAIR_ADMIN);
        factory.setQuoteToken(address(quote), true);

        vm.prank(PAIR_ADMIN);
        address pairAddr = factory.createPair(address(quote), address(base), 0, 0, COLLECTOR);
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

    function _path(address a, address b) internal pure returns (address[] memory p) {
        p = new address[](2);
        p[0] = a;
        p[1] = b;
    }

    function _absDiff(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a - b : b - a;
    }

    function _min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function test_regression_taxZero_swapMatchesFeeOnlyMath() public {
        (uint256 rq, uint256 rb) = _reservesQuoteBase();
        uint256 rawIn = 1000 ether;
        uint256 expectedOut = _getAmountOut(rawIn, rq, rb);

        quote.mint(TRADER, rawIn);
        vm.prank(TRADER);
        quote.transfer(address(pair), rawIn);

        if (_isQuote0()) {
            vm.prank(TRADER);
            pair.swap(0, expectedOut, TRADER, new bytes(0));
        } else {
            vm.prank(TRADER);
            pair.swap(expectedOut, 0, TRADER, new bytes(0));
        }

        assertEq(pair.accumulatedQuoteFees(), 0, "vault should remain zero");
    }

    function test_regression_taxZero_routerQuoteMatchesExecution_buyAndSell() public {
        uint256 quoteIn = 1_200 ether;
        address[] memory buyPath = _path(address(quote), address(base));
        uint256[] memory buyQuoted = router.getAmountsOut(quoteIn, buyPath);

        quote.mint(TRADER, quoteIn);
        vm.prank(TRADER);
        quote.approve(address(router), uint256(-1));
        uint256 baseBefore = base.balanceOf(TRADER);
        vm.prank(TRADER);
        router.swapExactTokensForTokens(quoteIn, buyQuoted[1], buyPath, TRADER, block.timestamp + 1);
        uint256 buyExecuted = base.balanceOf(TRADER) - baseBefore;
        assertEq(buyExecuted, buyQuoted[1], "tax=0 buy quote mismatch");

        uint256 baseIn = 1_500 ether;
        address[] memory sellPath = _path(address(base), address(quote));
        uint256[] memory sellQuoted = router.getAmountsOut(baseIn, sellPath);

        base.mint(TRADER, baseIn);
        vm.prank(TRADER);
        base.approve(address(router), uint256(-1));
        uint256 quoteBefore = quote.balanceOf(TRADER);
        vm.prank(TRADER);
        router.swapExactTokensForTokens(baseIn, sellQuoted[1], sellPath, TRADER, block.timestamp + 1);
        uint256 sellExecuted = quote.balanceOf(TRADER) - quoteBefore;
        assertLe(_absDiff(sellExecuted, sellQuoted[1]), 1, "tax=0 sell quote drift > 1 wei");
    }

    function test_regression_taxZero_feeToOff_mintBurnParity() public {
        assertEq(factory.feeTo(), address(0), "feeTo should be disabled");
        assertEq(pair.accumulatedQuoteFees(), 0, "vault should be zero when tax=0");

        (uint256 rq, uint256 rb) = _reservesQuoteBase();
        uint256 totalSupplyBefore = pair.totalSupply();
        uint256 addQuote = 2_000 ether;
        uint256 addBase = 2_000 ether;
        uint256 expectedMint = _min(addQuote * totalSupplyBefore / rq, addBase * totalSupplyBefore / rb);

        quote.mint(LP2, addQuote);
        base.mint(LP2, addBase);
        vm.prank(LP2);
        quote.transfer(address(pair), addQuote);
        vm.prank(LP2);
        base.transfer(address(pair), addBase);
        vm.prank(LP2);
        pair.mint(LP2);

        uint256 minted = pair.balanceOf(LP2);
        assertEq(minted, expectedMint, "mint parity mismatch at tax=0");

        (uint256 rqAfterMint, uint256 rbAfterMint) = _reservesQuoteBase();
        uint256 totalSupplyAfterMint = pair.totalSupply();
        uint256 expectedQuoteOut = minted * rqAfterMint / totalSupplyAfterMint;
        uint256 expectedBaseOut = minted * rbAfterMint / totalSupplyAfterMint;

        uint256 quoteBefore = quote.balanceOf(LP2);
        uint256 baseBefore = base.balanceOf(LP2);
        vm.prank(LP2);
        pair.transfer(address(pair), minted);
        vm.prank(LP2);
        pair.burn(LP2);

        assertEq(quote.balanceOf(LP2) - quoteBefore, expectedQuoteOut, "burn quote parity mismatch at tax=0");
        assertEq(base.balanceOf(LP2) - baseBefore, expectedBaseOut, "burn base parity mismatch at tax=0");
    }
}
