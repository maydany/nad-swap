// NadSwap V2 forked from Uniswap V2; modified for NadSwap requirements.
pragma solidity =0.5.16;

import "./interfaces/IERC20.sol";
import "./interfaces/INadSwapV2Callee.sol";
import "./interfaces/INadSwapV2Factory.sol";
import "./interfaces/INadSwapV2Pair.sol";
import "./libraries/Math.sol";
import "./libraries/SafeMath.sol";
import "./libraries/UQ112x112.sol";
import "./NadSwapV2ERC20.sol";

contract UniswapV2Pair is IUniswapV2Pair, UniswapV2ERC20 {
    using SafeMath for uint256;
    using UQ112x112 for uint224;

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

    // IMPORTANT: NadSwap-added fields are append-only after V2 original fields.
    address public quoteToken;
    uint16 public buyTaxBps;
    uint16 public sellTaxBps;
    bool private initialized;

    address public feeCollector;
    uint96 public accumulatedQuoteFees;

    uint16 public constant MAX_TAX_BPS = 2000;
    uint16 private constant BPS = 10_000;

    struct SwapVars {
        uint112 r0;
        uint112 r1;
        uint256 raw0;
        uint256 raw1;
        uint96 oldVault;
        bool isQuote0;
        uint256 rawQuote;
        uint256 eff0old;
        uint256 eff1old;
        uint256 grossAmount0Out;
        uint256 grossAmount1Out;
        uint256 quoteTaxOut;
        uint256 amount0In;
        uint256 amount1In;
        uint256 quoteTaxIn;
        uint96 newVault;
        uint256 eff0;
        uint256 eff1;
        uint256 effIn0;
        uint256 effIn1;
    }

    modifier lock() {
        require(unlocked == 1, "UniswapV2: LOCKED");
        unlocked = 0;
        _;
        unlocked = 1;
    }

    constructor() public {
        factory = msg.sender;
    }

    function getReserves() public view returns (uint112, uint112, uint32) {
        return (reserve0, reserve1, blockTimestampLast);
    }

    function _safeTransfer(address token, address to, uint256 value) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, to, value));
        require(success, "UniswapV2: TRANSFER_FAILED");
        if (data.length > 0) {
            require(abi.decode(data, (bool)), "UniswapV2: TRANSFER_FAILED");
        }
    }

    function initialize(
        address _token0,
        address _token1,
        address _quoteToken,
        uint16 _buyTaxBps,
        uint16 _sellTaxBps,
        address _feeCollector
    ) external {
        require(msg.sender == factory, "FORBIDDEN");
        require(!initialized, "ALREADY_INITIALIZED");
        require(_quoteToken == _token0 || _quoteToken == _token1, "INVALID_QUOTE");
        require(_feeCollector != address(0), "ZERO_COLLECTOR");
        require(_buyTaxBps <= MAX_TAX_BPS && _sellTaxBps <= MAX_TAX_BPS, "TAX_TOO_HIGH");
        require(_sellTaxBps < BPS, "SELL_TAX_INVALID");

        initialized = true;
        token0 = _token0;
        token1 = _token1;
        quoteToken = _quoteToken;
        buyTaxBps = _buyTaxBps;
        sellTaxBps = _sellTaxBps;
        feeCollector = _feeCollector;
    }

    function setTaxConfig(uint16 _buyTaxBps, uint16 _sellTaxBps, address _collector) external {
        require(msg.sender == factory, "FORBIDDEN");
        require(_buyTaxBps <= MAX_TAX_BPS && _sellTaxBps <= MAX_TAX_BPS, "TAX_TOO_HIGH");
        require(_sellTaxBps < BPS, "SELL_TAX_INVALID");
        require(_collector != address(0), "ZERO_COLLECTOR");

        buyTaxBps = _buyTaxBps;
        sellTaxBps = _sellTaxBps;
        feeCollector = _collector;

        emit TaxConfigUpdated(_buyTaxBps, _sellTaxBps, _collector);
    }

    function _effectiveBalances(uint256 raw0, uint256 raw1, uint96 vault)
        internal
        view
        returns (uint256 eff0, uint256 eff1)
    {
        bool isQuote0 = quoteToken == token0;
        if (isQuote0) {
            require(raw0 >= vault, "VAULT_DRIFT");
            eff0 = raw0.sub(vault);
            eff1 = raw1;
        } else {
            require(raw1 >= vault, "VAULT_DRIFT");
            eff0 = raw0;
            eff1 = raw1.sub(vault);
        }
    }

    function _update(uint256 balance0, uint256 balance1, uint112 _reserve0, uint112 _reserve1) private {
        require(balance0 <= uint112(-1) && balance1 <= uint112(-1), "UniswapV2: OVERFLOW");
        uint32 blockTimestamp = uint32(block.timestamp);
        uint32 timeElapsed = blockTimestamp - blockTimestampLast;
        if (timeElapsed > 0 && _reserve0 != 0 && _reserve1 != 0) {
            price0CumulativeLast += uint256(UQ112x112.encode(_reserve1).uqdiv(_reserve0)) * timeElapsed;
            price1CumulativeLast += uint256(UQ112x112.encode(_reserve0).uqdiv(_reserve1)) * timeElapsed;
        }
        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
        blockTimestampLast = blockTimestamp;
        emit Sync(reserve0, reserve1);
    }

    function _mintFee(uint112 _reserve0, uint112 _reserve1) private returns (bool feeOn) {
        address feeTo = IUniswapV2Factory(factory).feeTo();
        feeOn = feeTo != address(0);
        uint256 _kLast = kLast;
        if (feeOn) {
            if (_kLast != 0) {
                uint256 rootK = Math.sqrt(uint256(_reserve0).mul(_reserve1));
                uint256 rootKLast = Math.sqrt(_kLast);
                if (rootK > rootKLast) {
                    uint256 numerator = totalSupply.mul(rootK.sub(rootKLast));
                    uint256 denominator = rootK.mul(5).add(rootKLast);
                    uint256 liquidity = numerator / denominator;
                    if (liquidity > 0) _mint(feeTo, liquidity);
                }
            }
        } else if (_kLast != 0) {
            kLast = 0;
        }
    }

    function mint(address to) external lock returns (uint256 liquidity) {
        (uint112 _reserve0, uint112 _reserve1,) = getReserves();
        uint256 raw0 = IERC20(token0).balanceOf(address(this));
        uint256 raw1 = IERC20(token1).balanceOf(address(this));
        (uint256 balance0, uint256 balance1) = _effectiveBalances(raw0, raw1, accumulatedQuoteFees);

        uint256 amount0 = balance0.sub(_reserve0);
        uint256 amount1 = balance1.sub(_reserve1);

        bool feeOn = _mintFee(_reserve0, _reserve1);
        uint256 _totalSupply = totalSupply;
        if (_totalSupply < 1) {
            liquidity = Math.sqrt(amount0.mul(amount1)).sub(MINIMUM_LIQUIDITY);
            _mint(address(0), MINIMUM_LIQUIDITY);
        } else {
            liquidity = Math.min(amount0.mul(_totalSupply) / _reserve0, amount1.mul(_totalSupply) / _reserve1);
        }
        require(liquidity > 0, "UniswapV2: INSUFFICIENT_LIQUIDITY_MINTED");
        _mint(to, liquidity);

        _update(balance0, balance1, _reserve0, _reserve1);
        if (feeOn) kLast = uint256(reserve0).mul(reserve1);
        emit Mint(msg.sender, amount0, amount1);
    }

    // slither-disable-next-line reentrancy-no-eth
    function burn(address to) external lock returns (uint256 amount0, uint256 amount1) {
        (uint112 _reserve0, uint112 _reserve1,) = getReserves();
        address _token0 = token0;
        address _token1 = token1;

        uint256 raw0 = IERC20(_token0).balanceOf(address(this));
        uint256 raw1 = IERC20(_token1).balanceOf(address(this));
        (uint256 balance0, uint256 balance1) = _effectiveBalances(raw0, raw1, accumulatedQuoteFees);

        uint256 liquidity = balanceOf[address(this)];
        bool feeOn = _mintFee(_reserve0, _reserve1);
        uint256 _totalSupply = totalSupply;
        amount0 = liquidity.mul(balance0) / _totalSupply;
        amount1 = liquidity.mul(balance1) / _totalSupply;
        require(amount0 > 0 && amount1 > 0, "UniswapV2: INSUFFICIENT_LIQUIDITY_BURNED");
        _burn(address(this), liquidity);
        _safeTransfer(_token0, to, amount0);
        _safeTransfer(_token1, to, amount1);

        raw0 = IERC20(_token0).balanceOf(address(this));
        raw1 = IERC20(_token1).balanceOf(address(this));
        (balance0, balance1) = _effectiveBalances(raw0, raw1, accumulatedQuoteFees);
        _update(balance0, balance1, _reserve0, _reserve1);
        if (feeOn) kLast = uint256(reserve0).mul(reserve1);
        emit Burn(msg.sender, amount0, amount1, to);
    }

    function _calcIn(uint256 eff, uint112 reserve, uint256 outAmount) private pure returns (uint256) {
        uint256 target = uint256(reserve).sub(outAmount);
        return eff > target ? eff.sub(target) : 0;
    }

    // slither-disable-next-line reentrancy-no-eth
    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external lock {
        require(amount0Out > 0 || amount1Out > 0, "INSUFFICIENT_OUTPUT");
        require(amount0Out == 0 || amount1Out == 0, "SINGLE_SIDE_ONLY");
        require(to != token0 && to != token1, "INVALID_TO");

        SwapVars memory v = SwapVars(
            0, 0, 0, 0, 0, false, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
        );
        (v.r0, v.r1,) = getReserves();
        require(amount0Out < v.r0 && amount1Out < v.r1, "INSUFFICIENT_LIQUIDITY");

        if (amount0Out > 0) _safeTransfer(token0, to, amount0Out);
        if (amount1Out > 0) _safeTransfer(token1, to, amount1Out);
        if (data.length > 0) IUniswapV2Callee(to).uniswapV2Call(msg.sender, amount0Out, amount1Out, data);

        v.raw0 = IERC20(token0).balanceOf(address(this));
        v.raw1 = IERC20(token1).balanceOf(address(this));
        v.oldVault = accumulatedQuoteFees;
        v.isQuote0 = quoteToken == token0;
        v.rawQuote = v.isQuote0 ? v.raw0 : v.raw1;
        require(v.rawQuote >= v.oldVault, "VAULT_DRIFT");
        v.eff0old = v.isQuote0 ? v.raw0.sub(v.oldVault) : v.raw0;
        v.eff1old = v.isQuote0 ? v.raw1 : v.raw1.sub(v.oldVault);

        v.grossAmount0Out = amount0Out;
        v.grossAmount1Out = amount1Out;
        if (v.isQuote0 && amount0Out > 0) {
            v.grossAmount0Out = amount0Out.mul(BPS).add(BPS - sellTaxBps - 1) / (BPS - sellTaxBps);
            require(v.grossAmount0Out < v.r0, "INSUFFICIENT_LIQUIDITY_GROSS");
            v.quoteTaxOut = v.grossAmount0Out.sub(amount0Out);
        } else if (!v.isQuote0 && amount1Out > 0) {
            v.grossAmount1Out = amount1Out.mul(BPS).add(BPS - sellTaxBps - 1) / (BPS - sellTaxBps);
            require(v.grossAmount1Out < v.r1, "INSUFFICIENT_LIQUIDITY_GROSS");
            v.quoteTaxOut = v.grossAmount1Out.sub(amount1Out);
        }

        uint256 actualIn0 = _calcIn(v.eff0old, v.r0, amount0Out);
        uint256 actualIn1 = _calcIn(v.eff1old, v.r1, amount1Out);
        require(actualIn0 > 0 || actualIn1 > 0, "INSUFFICIENT_INPUT");

        v.amount0In = _calcIn(v.eff0old, v.r0, v.grossAmount0Out);
        v.amount1In = _calcIn(v.eff1old, v.r1, v.grossAmount1Out);

        if (v.isQuote0 && v.amount0In > 0 && amount1Out > 0) {
            v.quoteTaxIn = v.amount0In.mul(buyTaxBps) / BPS;
        } else if (!v.isQuote0 && v.amount1In > 0 && amount0Out > 0) {
            v.quoteTaxIn = v.amount1In.mul(buyTaxBps) / BPS;
        }

        uint256 _nv = uint256(v.oldVault).add(v.quoteTaxIn).add(v.quoteTaxOut);
        require(_nv <= uint96(-1), "VAULT_OVERFLOW");
        v.newVault = uint96(_nv);

        require(v.rawQuote >= v.newVault, "VAULT_DRIFT");
        v.eff0 = v.isQuote0 ? v.raw0.sub(v.newVault) : v.raw0;
        v.eff1 = v.isQuote0 ? v.raw1 : v.raw1.sub(v.newVault);

        v.effIn0 = _calcIn(v.eff0, v.r0, v.grossAmount0Out);
        v.effIn1 = _calcIn(v.eff1, v.r1, v.grossAmount1Out);

        uint256 adj0 = v.eff0.mul(1000).sub(v.effIn0.mul(2));
        uint256 adj1 = v.eff1.mul(1000).sub(v.effIn1.mul(2));
        if (adj0 > 0) {
            require(adj1 <= uint256(-1) / adj0, "K_MULTIPLY_OVERFLOW");
        }
        require(adj0.mul(adj1) >= uint256(v.r0).mul(v.r1).mul(1000**2), "K");

        accumulatedQuoteFees = v.newVault;
        _update(v.eff0, v.eff1, v.r0, v.r1);

        emit Swap(msg.sender, v.effIn0, v.effIn1, amount0Out, amount1Out, to);
        emit QuoteFeesAccrued(v.quoteTaxIn, v.quoteTaxOut, v.newVault);
    }

    function skim(address to) external lock {
        uint256 raw0 = IERC20(token0).balanceOf(address(this));
        uint256 raw1 = IERC20(token1).balanceOf(address(this));

        if (quoteToken == token0) {
            uint256 expectedQuote = uint256(reserve0).add(accumulatedQuoteFees);
            uint256 excessQuote = raw0 > expectedQuote ? raw0.sub(expectedQuote) : 0;
            if (excessQuote > 0) _safeTransfer(token0, to, excessQuote);

            uint256 excessBase = raw1 > reserve1 ? raw1.sub(reserve1) : 0;
            if (excessBase > 0) _safeTransfer(token1, to, excessBase);
        } else {
            uint256 expectedQuote = uint256(reserve1).add(accumulatedQuoteFees);
            uint256 excessQuote = raw1 > expectedQuote ? raw1.sub(expectedQuote) : 0;
            if (excessQuote > 0) _safeTransfer(token1, to, excessQuote);

            uint256 excessBase = raw0 > reserve0 ? raw0.sub(reserve0) : 0;
            if (excessBase > 0) _safeTransfer(token0, to, excessBase);
        }
    }

    function sync() external lock {
        uint256 raw0 = IERC20(token0).balanceOf(address(this));
        uint256 raw1 = IERC20(token1).balanceOf(address(this));
        (uint256 eff0, uint256 eff1) = _effectiveBalances(raw0, raw1, accumulatedQuoteFees);
        _update(eff0, eff1, reserve0, reserve1);
    }

    function claimQuoteFees(address to) external lock {
        require(msg.sender == feeCollector, "FORBIDDEN");
        require(to != address(0) && to != address(this), "INVALID_TO");

        uint96 fees = accumulatedQuoteFees;
        require(fees > 0, "NO_FEES");

        uint256 rawQuote = IERC20(quoteToken).balanceOf(address(this));
        require(rawQuote >= fees, "VAULT_DRIFT");

        accumulatedQuoteFees = 0;
        _safeTransfer(quoteToken, to, uint256(fees));

        uint256 raw0 = IERC20(token0).balanceOf(address(this));
        uint256 raw1 = IERC20(token1).balanceOf(address(this));
        (uint112 _reserve0, uint112 _reserve1,) = getReserves();
        _update(raw0, raw1, _reserve0, _reserve1);

        emit QuoteFeesClaimed(to, fees);
    }
}
