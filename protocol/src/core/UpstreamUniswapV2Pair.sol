pragma solidity =0.5.16;

import "./NadSwapV2ERC20.sol";

// Baseline V2 slot reference contract (no NadSwap extensions).
contract UpstreamUniswapV2Pair is UniswapV2ERC20 {
    uint256 public constant MINIMUM_LIQUIDITY = 10**3;
    bytes4 private constant SELECTOR = bytes4(keccak256(bytes("transfer(address,uint256)")));

    address public factory;
    address public token0;
    address public token1;

    uint112 private reserve0;
    uint112 private reserve1;
    uint32 private blockTimestampLast;

    uint256 public price0CumulativeLast;
    uint256 public price1CumulativeLast;
    uint256 public kLast;

    uint256 private unlocked = 1;

    constructor() public {
        factory = msg.sender;
    }
}
