pragma solidity =0.5.16;

import "../../src/core/UniswapV2Factory.sol";
import "../../src/core/UniswapV2Pair.sol";
import "../../src/core/interfaces/IERC20.sol";
import "../../src/periphery/UniswapV2Router02.sol";
import "./MockERC20.sol";
import "./MockWETH.sol";
import "./TestBase.sol";

contract PairFixture is TestBase {
    uint256 internal constant BPS = 10_000;
    uint256 internal constant INITIAL_LIQUIDITY = 1_000_000 ether;

    address internal constant FEE_TO_SETTER = address(0x100);
    address internal constant TAX_ADMIN = address(0x200);
    address internal constant COLLECTOR = address(0x300);
    address internal constant LP = address(0x111);
    address internal constant TRADER = address(0x222);
    address internal constant FEE_RECIPIENT = address(0x333);
    address internal constant OTHER = address(0x444);

    UniswapV2Factory internal factory;
    UniswapV2Pair internal pair;
    UniswapV2Router02 internal router;
    MockWETH internal weth;

    MockERC20 internal quote;
    MockERC20 internal base;
    address internal quoteTokenAddr;
    address internal baseTokenAddr;

    function _setUpPair(uint16 buyTaxBps, uint16 sellTaxBps) internal {
        quote = new MockERC20("Quote", "QT", 18);
        base = new MockERC20("Base", "BS", 18);
        quoteTokenAddr = address(quote);
        baseTokenAddr = address(base);
        _setUpPairWithTokens(quoteTokenAddr, baseTokenAddr, buyTaxBps, sellTaxBps, COLLECTOR);
    }

    function _setUpPairWithTokens(
        address quoteToken,
        address baseToken,
        uint16 buyTaxBps,
        uint16 sellTaxBps,
        address collector
    ) internal {
        quoteTokenAddr = quoteToken;
        baseTokenAddr = baseToken;

        weth = new MockWETH();
        factory = new UniswapV2Factory(FEE_TO_SETTER, TAX_ADMIN);
        router = new UniswapV2Router02(address(factory), address(weth));

        vm.prank(FEE_TO_SETTER);
        factory.setQuoteToken(quoteTokenAddr, true);
        vm.prank(FEE_TO_SETTER);
        factory.setBaseTokenSupported(baseTokenAddr, true);

        vm.prank(TAX_ADMIN);
        address pairAddr = factory.createPair(quoteTokenAddr, baseTokenAddr, buyTaxBps, sellTaxBps, collector);
        pair = UniswapV2Pair(pairAddr);

        _mintToken(quoteTokenAddr, LP, INITIAL_LIQUIDITY * 10);
        _mintToken(baseTokenAddr, LP, INITIAL_LIQUIDITY * 10);

        vm.prank(LP);
        _safeTokenTransfer(quoteTokenAddr, pairAddr, INITIAL_LIQUIDITY);
        vm.prank(LP);
        _safeTokenTransfer(baseTokenAddr, pairAddr, INITIAL_LIQUIDITY);
        vm.prank(LP);
        pair.mint(LP);
    }

    function _mintToken(address token, address to, uint256 amount) internal {
        (bool success,) = token.call(abi.encodeWithSignature("mint(address,uint256)", to, amount));
        require(success, "MINT_CALL_FAILED");
    }

    function _safeTokenTransfer(address token, address to, uint256 amount) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSignature("transfer(address,uint256)", to, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TRANSFER_CALL_FAILED");
    }

    function _safeTokenApprove(address token, address spender, uint256 amount) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSignature("approve(address,uint256)", spender, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "APPROVE_CALL_FAILED");
    }

    function _isQuote0() internal view returns (bool) {
        return pair.quoteToken() == pair.token0();
    }

    function _reservesQuoteBase() internal view returns (uint256 reserveQuote, uint256 reserveBase) {
        (uint112 r0, uint112 r1,) = pair.getReserves();
        if (_isQuote0()) {
            reserveQuote = uint256(r0);
            reserveBase = uint256(r1);
        } else {
            reserveQuote = uint256(r1);
            reserveBase = uint256(r0);
        }
    }

    function _rawQuoteBase() internal view returns (uint256 rawQuote, uint256 rawBase) {
        uint256 raw0 = IERC20(pair.token0()).balanceOf(address(pair));
        uint256 raw1 = IERC20(pair.token1()).balanceOf(address(pair));
        if (_isQuote0()) {
            rawQuote = raw0;
            rawBase = raw1;
        } else {
            rawQuote = raw1;
            rawBase = raw0;
        }
    }

    function _quoteBalance(address account) internal view returns (uint256) {
        return IERC20(quoteTokenAddr).balanceOf(account);
    }

    function _baseBalance(address account) internal view returns (uint256) {
        return IERC20(baseTokenAddr).balanceOf(account);
    }

    function _getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) internal pure returns (uint256) {
        uint256 amountInWithFee = amountIn * 998;
        return (amountInWithFee * reserveOut) / (reserveIn * 1000 + amountInWithFee);
    }

    function _getAmountIn(uint256 amountOut, uint256 reserveIn, uint256 reserveOut) internal pure returns (uint256) {
        return (reserveIn * amountOut * 1000) / ((reserveOut - amountOut) * 998) + 1;
    }

    function _ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a + b - 1) / b;
    }

    function _buy(uint256 rawQuoteIn, uint256 baseOut, address trader) internal {
        _mintToken(quoteTokenAddr, trader, rawQuoteIn);
        vm.prank(trader);
        _safeTokenTransfer(quoteTokenAddr, address(pair), rawQuoteIn);

        if (_isQuote0()) {
            vm.prank(trader);
            pair.swap(0, baseOut, trader, new bytes(0));
        } else {
            vm.prank(trader);
            pair.swap(baseOut, 0, trader, new bytes(0));
        }
    }

    function _sell(uint256 baseIn, uint256 netQuoteOut, address trader) internal {
        _mintToken(baseTokenAddr, trader, baseIn);
        vm.prank(trader);
        _safeTokenTransfer(baseTokenAddr, address(pair), baseIn);

        if (_isQuote0()) {
            vm.prank(trader);
            pair.swap(netQuoteOut, 0, trader, new bytes(0));
        } else {
            vm.prank(trader);
            pair.swap(0, netQuoteOut, trader, new bytes(0));
        }
    }

    function _path(address a, address b) internal pure returns (address[] memory p) {
        p = new address[](2);
        p[0] = a;
        p[1] = b;
    }

    function _approveRouter(address token, address owner, uint256 amount) internal {
        vm.prank(owner);
        _safeTokenApprove(token, address(router), amount);
    }

    function _setVault(uint96 newVault) internal {
        uint256 slot = 14;
        uint256 packed = uint256(vm.load(address(pair), bytes32(slot)));
        uint256 lowMask = uint256(-1) >> 96; // low 160 bits = feeCollector
        uint256 nextPacked = (packed & lowMask) | (uint256(newVault) << 160);
        vm.store(address(pair), bytes32(slot), bytes32(nextPacked));
    }
}
