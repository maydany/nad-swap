pragma solidity =0.5.16;

import "../helpers/ForkFixture.sol";
import "../../helpers/MockERC20.sol";

contract ForkCoreFactoryPolicyTest is ForkFixture {
    function setUp() public {
        _setUpFork();
    }

    function testFork_factory_createPair_onlyPairAdmin() public onlyFork {
        vm.prank(OTHER);
        expectRevertMsg("FORBIDDEN");
        factory.createPair(monadQuoteToken, monadBaseToken, 300, 500, COLLECTOR);
    }

    function testFork_factory_quoteRequired_revert() public onlyFork {
        vm.prank(PAIR_ADMIN);
        expectRevertMsg("QUOTE_REQUIRED");
        factory.createPair(monadBaseToken, monadWnative, 300, 500, COLLECTOR);
    }

    function testFork_factory_unlistedBase_success() public onlyFork {
        MockERC20 unsupported = new MockERC20("Unsupported", "UNS", 18);
        vm.prank(PAIR_ADMIN);
        address pairAddr = factory.createPair(monadQuoteToken, address(unsupported), 300, 500, COLLECTOR);
        assertTrue(pairAddr != address(0), "pair should be created without base allowlist");
    }

    function testFork_factory_duplicate_revert() public onlyFork {
        vm.prank(PAIR_ADMIN);
        expectRevertMsg("UniswapV2: PAIR_EXISTS");
        factory.createPair(monadQuoteToken, monadBaseToken, 300, 500, COLLECTOR);
    }

    function testFork_factory_setTaxConfig_mutable() public onlyFork {
        vm.prank(PAIR_ADMIN);
        factory.setTaxConfig(address(pair), 100, 200, OTHER);
        assertEq(uint256(pair.buyTaxBps()), 100, "buy tax mismatch");
        assertEq(uint256(pair.sellTaxBps()), 200, "sell tax mismatch");
        assertEq(pair.feeCollector(), OTHER, "collector mismatch");
    }

    function testFork_factory_setQuoteToken_nonPairAdmin_revert() public onlyFork {
        vm.prank(OTHER);
        expectRevertMsg("FORBIDDEN");
        factory.setQuoteToken(monadQuoteToken, false);
    }

    function testFork_factory_baseAllowlistSetter_removed() public onlyFork {
        (bool success,) = address(factory).call(
            abi.encodeWithSignature("setBaseTokenSupported(address,bool)", monadBaseToken, false)
        );
        assertTrue(!success, "setBaseTokenSupported path should not exist");
    }

    function testFork_factory_baseAllowlistGetter_removed() public onlyFork {
        (bool success,) = address(factory).call(abi.encodeWithSignature("isBaseTokenSupported(address)", monadBaseToken));
        assertTrue(!success, "isBaseTokenSupported path should not exist");
    }
}
