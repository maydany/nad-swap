pragma solidity =0.5.16;

import "../helpers/ForkFixture.sol";

contract ForkPolicyGuardsTest is ForkFixture {
    function setUp() public {
        _setUpFork();
    }

    function testFork_policy_quoteDisabled_revert() public onlyFork {
        _setQuoteDisabled();
        _fundQuote(TRADER, 2 ether);
        _approveRouter(monadQuoteToken, TRADER, uint256(-1));
        address[] memory p = _path(monadQuoteToken, monadBaseToken);
        vm.prank(TRADER);
        expectRevertMsg("QUOTE_NOT_SUPPORTED");
        router.swapExactTokensForTokens(2 ether, 0, p, TRADER, block.timestamp + 1);
    }

    function testFork_policy_fotSupportingEntrypoints_revert() public onlyFork {
        address[] memory p = _path(monadQuoteToken, monadBaseToken);
        expectRevertMsg("FOT_NOT_SUPPORTED");
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(1, 0, p, TRADER, block.timestamp + 1);
        expectRevertMsg("FOT_NOT_SUPPORTED");
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(1, 0, p, TRADER, block.timestamp + 1);
        expectRevertMsg("FOT_NOT_SUPPORTED");
        router.swapExactETHForTokensSupportingFeeOnTransferTokens(0, p, TRADER, block.timestamp + 1);
    }

    function testFork_policy_quoteToken_invariant_guard() public onlyFork {
        (uint256 rawQuote,) = _rawQuoteBase();
        _setVault(uint96(rawQuote + 1));
        expectRevertMsg("VAULT_DRIFT");
        pair.sync();
    }
}
