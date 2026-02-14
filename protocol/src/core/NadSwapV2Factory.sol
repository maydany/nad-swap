// NadSwap V2 forked from Uniswap V2; modified for NadSwap requirements.
pragma solidity =0.5.16;

import "./interfaces/INadSwapV2Factory.sol";
import "./interfaces/INadSwapV2Pair.sol";
import "./NadSwapV2Pair.sol";

contract UniswapV2Factory is IUniswapV2Factory {
    address public feeTo;
    address public pairAdmin;

    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;

    mapping(address => bool) public isQuoteToken;
    mapping(address => bool) public isPair;

    modifier onlyValidPair(address pair) {
        require(isPair[pair], "INVALID_PAIR");
        _;
    }

    constructor(address _pairAdmin) public {
        require(_pairAdmin != address(0), "ZERO_ADDRESS");
        pairAdmin = _pairAdmin;
    }

    function allPairsLength() external view returns (uint256) {
        return allPairs.length;
    }

    function createPair(
        address tokenA,
        address tokenB,
        uint16 buyTaxBps,
        uint16 sellTaxBps,
        address taxCollector
    ) external returns (address pair) {
        require(msg.sender == pairAdmin, "FORBIDDEN");
        require(tokenA != tokenB, "UniswapV2: IDENTICAL_ADDRESSES");
        (address token0, address token1) =
            tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), "UniswapV2: ZERO_ADDRESS");
        require(getPair[token0][token1] == address(0), "UniswapV2: PAIR_EXISTS");

        require(!(isQuoteToken[token0] && isQuoteToken[token1]), "BOTH_QUOTE");

        address qt;
        if (isQuoteToken[token0]) {
            qt = token0;
        } else if (isQuoteToken[token1]) {
            qt = token1;
        } else {
            revert("QUOTE_REQUIRED");
        }

        bytes memory bytecode = type(UniswapV2Pair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair;
        allPairs.push(pair);
        isPair[pair] = true;

        IUniswapV2Pair(pair).initialize(token0, token1, qt, buyTaxBps, sellTaxBps, taxCollector);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    function setTaxConfig(address pair, uint16 buyTaxBps, uint16 sellTaxBps, address taxCollector)
        external
        onlyValidPair(pair)
    {
        require(msg.sender == pairAdmin, "FORBIDDEN");
        IUniswapV2Pair(pair).setTaxConfig(buyTaxBps, sellTaxBps, taxCollector);
    }

    function setQuoteToken(address token, bool enabled) external {
        require(msg.sender == pairAdmin, "FORBIDDEN");
        require(token != address(0), "ZERO_ADDRESS");
        isQuoteToken[token] = enabled;
    }

    function setFeeTo(address _feeTo) external {
        require(msg.sender == pairAdmin, "UniswapV2: FORBIDDEN");
        feeTo = _feeTo;
    }
}
