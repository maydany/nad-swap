// NadSwap V2 forked from Uniswap V2; modified for NadSwap requirements.
pragma solidity =0.5.16;

interface IUniswapV2Callee {
    function uniswapV2Call(address sender, uint256 amount0, uint256 amount1, bytes calldata data) external;
}
