pragma solidity =0.5.16;

import "../../helpers/TestBase.sol";
import "../../../src/core/NadSwapV2Factory.sol";
import "../../../src/core/NadSwapV2Pair.sol";
import "../../../src/core/interfaces/IERC20.sol";
import "../../../src/periphery/NadSwapV2Router02.sol";

contract PairHandler is TestBase {
    uint256 internal constant BPS = 10_000;

    UniswapV2Factory public factory;
    UniswapV2Pair public pair;
    UniswapV2Router02 public router;

    address public quoteToken;
    address public baseToken;
    address public lp;
    address public feeCollector;
    address public pairAdmin;

    uint256 public actionCount;
    uint256 public maxRouterQuoteExecDiff;
    uint256 public vaultDecreaseViolations;
    uint256 public lastVault;

    bool private allowVaultDecrease;

    constructor(
        address _factory,
        address _pair,
        address _router,
        address _quoteToken,
        address _baseToken,
        address _lp,
        address _feeCollector,
        address _pairAdmin
    ) public {
        factory = UniswapV2Factory(_factory);
        pair = UniswapV2Pair(_pair);
        router = UniswapV2Router02(address(uint160(_router)));
        quoteToken = _quoteToken;
        baseToken = _baseToken;
        lp = _lp;
        feeCollector = _feeCollector;
        pairAdmin = _pairAdmin;
        lastVault = pair.accumulatedQuoteFees();
    }

    function buy(uint256 seed) external {
        actionCount += 1;

        (uint256 reserveQuote, uint256 reserveBase) = _reservesQuoteBase();
        if (reserveQuote == 0 || reserveBase == 0) return;

        uint256 cap = reserveQuote / 200;
        if (cap == 0) return;

        uint256 rawQuoteIn = seed % cap + 1;
        uint256 buyTax = pair.buyTaxBps();
        uint256 effIn = rawQuoteIn - (rawQuoteIn * buyTax / BPS);
        if (effIn == 0) return;

        uint256 baseOut = _getAmountOut(effIn, reserveQuote, reserveBase);
        if (baseOut == 0) return;

        address trader = _actor(seed, 0xA1);
        _mintToken(quoteToken, trader, rawQuoteIn);

        vm.prank(trader);
        _safeTokenTransfer(quoteToken, address(pair), rawQuoteIn);

        if (_isQuote0()) {
            vm.prank(trader);
            pair.swap(0, baseOut, trader, new bytes(0));
        } else {
            vm.prank(trader);
            pair.swap(baseOut, 0, trader, new bytes(0));
        }

        _postActionVaultCheck();
    }

    function sell(uint256 seed) external {
        actionCount += 1;

        (uint256 reserveQuote, uint256 reserveBase) = _reservesQuoteBase();
        if (reserveQuote == 0 || reserveBase == 0) return;

        uint256 cap = reserveQuote / 200;
        if (cap <= 1) return;

        uint256 netQuoteOut = seed % cap + 1;
        uint256 grossQuoteOut = _ceilDiv(netQuoteOut * BPS, BPS - pair.sellTaxBps());
        if (grossQuoteOut >= reserveQuote) return;

        uint256 baseIn = _getAmountIn(grossQuoteOut, reserveBase, reserveQuote);
        if (baseIn == 0) return;

        address trader = _actor(seed, 0xB2);
        _mintToken(baseToken, trader, baseIn);

        vm.prank(trader);
        _safeTokenTransfer(baseToken, address(pair), baseIn);

        if (_isQuote0()) {
            vm.prank(trader);
            pair.swap(netQuoteOut, 0, trader, new bytes(0));
        } else {
            vm.prank(trader);
            pair.swap(0, netQuoteOut, trader, new bytes(0));
        }

        _postActionVaultCheck();
    }

    function mint(uint256 seed) external {
        actionCount += 1;

        (uint256 reserveQuote, uint256 reserveBase) = _reservesQuoteBase();
        if (reserveQuote == 0 || reserveBase == 0) return;

        uint256 addQuote = reserveQuote / 1_000 + (seed % 1e12) + 1;
        uint256 addBase = reserveBase / 1_000 + ((seed >> 128) % 1e12) + 1;
        address provider = _actor(seed, 0xC3);

        _mintToken(quoteToken, provider, addQuote);
        _mintToken(baseToken, provider, addBase);

        vm.prank(provider);
        _safeTokenTransfer(quoteToken, address(pair), addQuote);
        vm.prank(provider);
        _safeTokenTransfer(baseToken, address(pair), addBase);
        vm.prank(provider);
        pair.mint(provider);

        _postActionVaultCheck();
    }

    function burn(uint256 seed) external {
        actionCount += 1;

        uint256 lpBalance = pair.balanceOf(lp);
        if (lpBalance <= pair.MINIMUM_LIQUIDITY()) {
            _postActionVaultCheck();
            return;
        }

        uint256 burnAmount = lpBalance / ((seed % 20) + 2);
        if (burnAmount == 0) {
            _postActionVaultCheck();
            return;
        }

        vm.prank(lp);
        pair.transfer(address(pair), burnAmount);
        vm.prank(lp);
        pair.burn(lp);

        _postActionVaultCheck();
    }

    function sync(uint256) external {
        actionCount += 1;
        pair.sync();
        _postActionVaultCheck();
    }

    function claim(uint256 seed) external {
        actionCount += 1;

        uint256 fees = pair.accumulatedQuoteFees();
        if (fees == 0) {
            _postActionVaultCheck();
            return;
        }

        allowVaultDecrease = true;
        address recipient = _recipient(seed, 0xD4);
        vm.prank(feeCollector);
        pair.claimQuoteFees(recipient);

        _postActionVaultCheck();
    }

    function setTaxConfig(uint256 seed) external {
        actionCount += 1;

        uint16 buyTax = uint16(seed % 2001);
        uint16 sellTax = uint16((seed >> 16) % 2001);
        address collector = _recipient(seed, 0xE5);

        vm.prank(pairAdmin);
        factory.setTaxConfig(address(pair), buyTax, sellTax, collector);
        feeCollector = collector;

        _postActionVaultCheck();
    }

    function routerQuoteExecute(uint256 seed) external {
        actionCount += 1;

        bool sellPath = (seed & 1) == 1;
        address trader = _actor(seed, 0xF6);
        if (sellPath) {
            _routerQuoteExecSell(seed, trader);
        } else {
            _routerQuoteExecBuy(seed, trader);
        }
        _postActionVaultCheck();
    }

    function _routerQuoteExecBuy(uint256 seed, address trader) internal {
        (, uint256 reserveBase) = _reservesQuoteBase();
        uint256 amountIn = seed % (reserveBase / 100 + 1) + 1;

        address[] memory path = new address[](2);
        path[0] = quoteToken;
        path[1] = baseToken;

        uint256[] memory quoted = router.getAmountsOut(amountIn, path);
        if (quoted[1] == 0) return;

        _mintToken(quoteToken, trader, amountIn);
        vm.prank(trader);
        _safeTokenApprove(quoteToken, address(router), uint256(-1));

        uint256 beforeOut = IERC20(baseToken).balanceOf(trader);
        vm.prank(trader);
        router.swapExactTokensForTokens(amountIn, 0, path, trader, block.timestamp + 1);
        uint256 executed = IERC20(baseToken).balanceOf(trader) - beforeOut;

        uint256 diff = _absDiff(executed, quoted[1]);
        if (diff > maxRouterQuoteExecDiff) maxRouterQuoteExecDiff = diff;
    }

    function _routerQuoteExecSell(uint256 seed, address trader) internal {
        (uint256 reserveQuote,) = _reservesQuoteBase();
        uint256 amountIn = seed % (reserveQuote / 100 + 1) + 1;

        address[] memory path = new address[](2);
        path[0] = baseToken;
        path[1] = quoteToken;

        uint256[] memory quoted = router.getAmountsOut(amountIn, path);
        if (quoted[1] == 0) return;

        _mintToken(baseToken, trader, amountIn);
        vm.prank(trader);
        _safeTokenApprove(baseToken, address(router), uint256(-1));

        uint256 beforeOut = IERC20(quoteToken).balanceOf(trader);
        vm.prank(trader);
        router.swapExactTokensForTokens(amountIn, 0, path, trader, block.timestamp + 1);
        uint256 executed = IERC20(quoteToken).balanceOf(trader) - beforeOut;

        uint256 diff = _absDiff(executed, quoted[1]);
        if (diff > maxRouterQuoteExecDiff) maxRouterQuoteExecDiff = diff;
    }

    function _postActionVaultCheck() internal {
        uint256 currentVault = pair.accumulatedQuoteFees();
        if (currentVault < lastVault && !allowVaultDecrease) {
            vaultDecreaseViolations += 1;
        }
        allowVaultDecrease = false;
        lastVault = currentVault;
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

    function _absDiff(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a - b : b - a;
    }

    function _actor(uint256 seed, uint256 salt) internal pure returns (address) {
        uint160 v = uint160(uint256(keccak256(abi.encodePacked(seed, salt))));
        if (v == 0) v = 1;
        return address(v);
    }

    function _recipient(uint256 seed, uint256 salt) internal view returns (address to) {
        to = _actor(seed, salt);
        if (to == address(pair)) {
            to = address(uint160(uint256(keccak256(abi.encodePacked(seed, salt, uint256(1))))));
        }
        if (to == address(0)) to = address(1);
    }
}
