// NadSwap V2 forked from Uniswap V2; modified for NadSwap requirements.
pragma solidity =0.5.16;

import "./INadSwapV2ERC20.sol";

contract IUniswapV2Pair is IUniswapV2ERC20 {
    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    event TaxConfigUpdated(uint16 buyTaxBps, uint16 sellTaxBps, address feeCollector);
    event QuoteFeesAccrued(uint256 quoteTaxIn, uint256 quoteTaxOut, uint256 accumulatedQuoteFees);
    event QuoteFeesClaimed(address indexed to, uint256 amount);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function quoteToken() external view returns (address);

    function buyTaxBps() external view returns (uint16);

    function sellTaxBps() external view returns (uint16);

    function feeCollector() external view returns (address);

    function accumulatedQuoteFees() external view returns (uint96);

    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function initialize(
        address _token0,
        address _token1,
        address _quoteToken,
        uint16 _buyTaxBps,
        uint16 _sellTaxBps,
        address _feeCollector
    ) external;

    function setTaxConfig(uint16 _buyTaxBps, uint16 _sellTaxBps, address _feeCollector) external;

    function claimQuoteFees(address to) external;

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to) external returns (uint256 amount0, uint256 amount1);

    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external;

    function skim(address to) external;

    function sync() external;
}
