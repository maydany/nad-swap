pragma solidity =0.5.16;

import "../../src/core/UniswapV2Factory.sol";
import "../../src/core/interfaces/IUniswapV2Factory.sol";
import "../helpers/MockERC20.sol";
import "../helpers/TestBase.sol";

contract FactoryTest is TestBase {
    UniswapV2Factory internal factory;
    MockERC20 internal quote;
    MockERC20 internal base;
    MockERC20 internal alt;

    address internal constant FEE_TO_SETTER = address(0x100);
    address internal constant PAIR_ADMIN = address(0x200);
    address internal constant COLLECTOR = address(0x300);
    address internal constant OTHER = address(0x400);

    function setUp() public {
        quote = new MockERC20("Quote", "QT", 18);
        base = new MockERC20("Base", "BS", 18);
        alt = new MockERC20("Alt", "ALT", 18);
        factory = new UniswapV2Factory(FEE_TO_SETTER, PAIR_ADMIN);

        vm.prank(FEE_TO_SETTER);
        factory.setQuoteToken(address(quote), true);

        vm.prank(FEE_TO_SETTER);
        factory.setBaseTokenSupported(address(base), true);
    }

    function test_constructor_zeroAddress_revert() public {
        expectRevertMsg("ZERO_ADDRESS");
        new UniswapV2Factory(address(0), PAIR_ADMIN);

        expectRevertMsg("ZERO_ADDRESS");
        new UniswapV2Factory(FEE_TO_SETTER, address(0));
    }

    function test_createPair_onlyPairAdmin() public {
        vm.prank(OTHER);
        expectRevertMsg("FORBIDDEN");
        factory.createPair(address(quote), address(base), 300, 500, COLLECTOR);
    }

    function test_createPair_bothQuote_revert() public {
        vm.prank(FEE_TO_SETTER);
        factory.setQuoteToken(address(alt), true);

        vm.prank(PAIR_ADMIN);
        expectRevertMsg("BOTH_QUOTE");
        factory.createPair(address(quote), address(alt), 300, 500, COLLECTOR);
    }

    function test_createPair_noQuote_revert() public {
        vm.prank(PAIR_ADMIN);
        expectRevertMsg("QUOTE_REQUIRED");
        factory.createPair(address(base), address(alt), 300, 500, COLLECTOR);
    }

    function test_createPair_baseUnsupported_revert() public {
        vm.prank(PAIR_ADMIN);
        expectRevertMsg("BASE_NOT_SUPPORTED");
        factory.createPair(address(quote), address(alt), 300, 500, COLLECTOR);
    }

    function test_createPair_duplicate_revert() public {
        vm.prank(PAIR_ADMIN);
        address pair = factory.createPair(address(quote), address(base), 300, 500, COLLECTOR);
        assertTrue(pair != address(0), "pair not created");

        vm.prank(PAIR_ADMIN);
        expectRevertMsg("UniswapV2: PAIR_EXISTS");
        factory.createPair(address(quote), address(base), 300, 500, COLLECTOR);
    }

    function test_setTaxConfig_maxTax_revert() public {
        vm.prank(PAIR_ADMIN);
        address pair = factory.createPair(address(quote), address(base), 300, 500, COLLECTOR);

        vm.prank(PAIR_ADMIN);
        expectRevertMsg("TAX_TOO_HIGH");
        factory.setTaxConfig(pair, 2001, 100, COLLECTOR);
    }

    function test_setQuoteToken_zeroAddr_revert() public {
        vm.prank(FEE_TO_SETTER);
        expectRevertMsg("ZERO_ADDRESS");
        factory.setQuoteToken(address(0), true);
    }

    function test_setBaseTokenSupported_forbidden() public {
        vm.prank(OTHER);
        expectRevertMsg("FORBIDDEN");
        factory.setBaseTokenSupported(address(base), true);
    }
}
