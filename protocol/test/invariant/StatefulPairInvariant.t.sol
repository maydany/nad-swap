pragma solidity =0.5.16;

import "../helpers/TestBase.sol";
import "../helpers/MockERC20.sol";
import "../helpers/MockWETH.sol";
import "../../src/core/UniswapV2Factory.sol";
import "../../src/core/UniswapV2Pair.sol";
import "../../src/core/interfaces/IERC20.sol";
import "../../src/periphery/UniswapV2Router02.sol";
import "./handlers/PairHandler.t.sol";

contract StatefulPairInvariantTest is TestBase {
    address internal constant PAIR_ADMIN = address(0x200);
    address internal constant COLLECTOR = address(0x300);
    address internal constant LP = address(0x111);

    MockERC20 internal quote;
    MockERC20 internal base;
    MockWETH internal weth;
    UniswapV2Factory internal factory;
    UniswapV2Pair internal pair;
    UniswapV2Router02 internal router;
    PairHandler internal handler;

    function setUp() public {
        quote = new MockERC20("Quote", "QT", 18);
        base = new MockERC20("Base", "BS", 18);
        weth = new MockWETH();

        factory = new UniswapV2Factory(PAIR_ADMIN);
        router = new UniswapV2Router02(address(factory), address(weth));

        vm.prank(PAIR_ADMIN);
        factory.setQuoteToken(address(quote), true);
        vm.prank(PAIR_ADMIN);
        factory.setBaseTokenSupported(address(base), true);

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

        handler = new PairHandler(
            address(factory),
            address(pair),
            address(router),
            address(quote),
            address(base),
            LP,
            COLLECTOR,
            PAIR_ADMIN
        );
    }

    function targetContracts() public view returns (address[] memory targets) {
        targets = new address[](1);
        targets[0] = address(handler);
    }

    function invariant_raw_quote_eq_reserve_plus_vault_or_dust() public view {
        (uint112 r0, uint112 r1,) = pair.getReserves();
        uint256 reserveQuote = _isQuote0() ? uint256(r0) : uint256(r1);
        uint256 rawQuote = IERC20(address(quote)).balanceOf(address(pair));
        uint256 vault = pair.accumulatedQuoteFees();

        assertGe(rawQuote, reserveQuote + vault, "raw quote fell below reserve+vault");
    }

    function invariant_vault_monotonic_except_claim() public view {
        assertEq(handler.vaultDecreaseViolations(), 0, "unexpected vault decrease");
    }

    function invariant_totalSupply_implies_positive_reserves() public view {
        uint256 totalSupply = pair.totalSupply();
        if (totalSupply > 0) {
            (uint112 r0, uint112 r1,) = pair.getReserves();
            assertTrue(r0 > 0, "reserve0 must be positive when LP supply exists");
            assertTrue(r1 > 0, "reserve1 must be positive when LP supply exists");
        }
    }

    function invariant_factory_pair_mapping_consistency() public view {
        assertTrue(factory.isPair(address(pair)), "pair must remain registered");
        assertEq(factory.getPair(address(quote), address(base)), address(pair), "forward mapping mismatch");
        assertEq(factory.getPair(address(base), address(quote)), address(pair), "reverse mapping mismatch");
    }

    function invariant_router_quote_exec_error_le_1wei_executable_domain() public view {
        assertLe(handler.maxRouterQuoteExecDiff(), 1, "router quote/execution diff exceeded 1 wei");
    }

    function _isQuote0() internal view returns (bool) {
        return pair.quoteToken() == pair.token0();
    }
}
