pragma solidity =0.5.16;

import "../../src/core/interfaces/INadSwapV2Callee.sol";
import "../../src/core/interfaces/INadSwapV2Pair.sol";

contract MockFlashCallee is IUniswapV2Callee {
    address public pair;
    address public repayToken;
    uint256 public repayAmount;

    function execute(
        address _pair,
        uint256 amount0Out,
        uint256 amount1Out,
        address _repayToken,
        uint256 _repayAmount
    ) external {
        pair = _pair;
        repayToken = _repayToken;
        repayAmount = _repayAmount;
        IUniswapV2Pair(_pair).swap(amount0Out, amount1Out, address(this), hex"01");
    }

    function uniswapV2Call(address, uint256, uint256, bytes calldata) external {
        require(msg.sender == pair, "PAIR_ONLY");
        if (repayAmount > 0) {
            (bool success, bytes memory data) =
                repayToken.call(abi.encodeWithSignature("transfer(address,uint256)", pair, repayAmount));
            require(success && (data.length == 0 || abi.decode(data, (bool))), "REPAY_FAILED");
        }
    }
}
