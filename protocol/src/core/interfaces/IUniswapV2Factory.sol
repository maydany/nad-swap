pragma solidity =0.5.16;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

    function feeTo() external view returns (address);

    function pairAdmin() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function isQuoteToken(address token) external view returns (bool);

    function isPair(address pair) external view returns (bool);

    function createPair(
        address tokenA,
        address tokenB,
        uint16 buyTaxBps,
        uint16 sellTaxBps,
        address feeCollector
    ) external returns (address pair);

    function setFeeTo(address) external;

    function setQuoteToken(address token, bool enabled) external;

    function setTaxConfig(address pair, uint16 buyTaxBps, uint16 sellTaxBps, address feeCollector) external;
}
