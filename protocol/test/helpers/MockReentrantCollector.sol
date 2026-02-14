pragma solidity =0.5.16;

import "../../src/core/interfaces/IUniswapV2Callee.sol";
import "../../src/core/interfaces/IUniswapV2Pair.sol";

contract MockReentrantCollector is IUniswapV2Callee {
    address public pair;
    address public repayToken;
    uint256 public repayAmount;
    bool public callbackEntered;
    bool public claimCallSucceeded;

    function setPair(address _pair) external {
        pair = _pair;
    }

    function setRepay(address _repayToken, uint256 _repayAmount) external {
        repayToken = _repayToken;
        repayAmount = _repayAmount;
    }

    function claim(address to) external {
        IUniswapV2Pair(pair).claimQuoteFees(to);
    }

    function uniswapV2Call(address, uint256, uint256, bytes calldata) external {
        require(msg.sender == pair, "PAIR_ONLY");
        callbackEntered = true;
        (claimCallSucceeded,) = pair.call(abi.encodeWithSignature("claimQuoteFees(address)", address(this)));

        if (repayAmount > 0) {
            (bool success, bytes memory data) =
                repayToken.call(abi.encodeWithSignature("transfer(address,uint256)", pair, repayAmount));
            require(success && (data.length == 0 || abi.decode(data, (bool))), "REPAY_FAILED");
        }
    }
}
