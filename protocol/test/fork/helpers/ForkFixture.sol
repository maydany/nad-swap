pragma solidity =0.5.16;

import "../../../src/core/NadSwapV2Factory.sol";
import "../../../src/core/NadSwapV2Pair.sol";
import "../../../src/core/interfaces/IERC20.sol";
import "../../../src/periphery/NadSwapV2Router02.sol";
import "../../../src/periphery/libraries/NadSwapV2Library.sol";
import "../../helpers/TestBase.sol";
import "../../helpers/MockERC20.sol";
import "../../helpers/MockWETH.sol";

contract ForkFixture is TestBase {
    uint256 internal constant BPS = 10_000;

    address internal constant PAIR_ADMIN = address(0x200);
    address internal constant COLLECTOR = address(0x300);
    address internal constant LP = address(0x111);
    address internal constant TRADER = address(0x222);
    address internal constant OTHER = address(0x444);

    bool internal forkEnabled;
    address internal monadWnative;
    address internal monadQuoteToken;
    address internal monadBaseToken;

    UniswapV2Factory internal factory;
    UniswapV2Router02 internal router;
    UniswapV2Pair internal pair;

    modifier onlyFork() {
        // Prevent false-positive fork suite passes when env is missing.
        require(forkEnabled, "FORK_NOT_ENABLED");
        _;
    }

    function _setUpFork() internal {
        forkEnabled = vm.envOr("MONAD_FORK_ENABLED", uint256(0)) == 1;
        if (!forkEnabled) {
            return;
        }

        // Optional real-RPC fork mode:
        // - default (`MONAD_FORK_USE_RPC=0`): run fork suite against local in-memory chain
        // - set `MONAD_FORK_USE_RPC=1` to require MONAD_RPC_URL and create an actual RPC fork
        bool useRpcFork = vm.envOr("MONAD_FORK_USE_RPC", uint256(0)) == 1;
        if (useRpcFork) {
            string memory rpcUrl = vm.envString("MONAD_RPC_URL");
            require(bytes(rpcUrl).length > 0, "MONAD_RPC_URL_EMPTY");
            uint256 forkBlock = vm.envOr("MONAD_FORK_BLOCK", uint256(0));
            if (forkBlock == 0) {
                vm.createSelectFork(rpcUrl);
            } else {
                vm.createSelectFork(rpcUrl, forkBlock);
            }
        }

        // Deploy mock tokens on the fork — no whale addresses needed
        MockWETH weth = new MockWETH();
        MockERC20 quote = new MockERC20("ForkQuote", "FQ", 18);
        MockERC20 base = new MockERC20("ForkBase", "FB", 18);

        monadWnative = address(weth);
        monadQuoteToken = address(quote);
        monadBaseToken = address(base);

        factory = new UniswapV2Factory(PAIR_ADMIN);
        router = new UniswapV2Router02(address(factory), monadWnative);

        vm.prank(PAIR_ADMIN);
        factory.setQuoteToken(monadQuoteToken, true);

        vm.prank(PAIR_ADMIN);
        address pairAddr = factory.createPair(monadQuoteToken, monadBaseToken, 300, 500, COLLECTOR);
        pair = UniswapV2Pair(pairAddr);

        // Mint and provide initial liquidity
        uint256 initLiq = 1_000_000 ether;
        quote.mint(LP, initLiq);
        base.mint(LP, initLiq);

        vm.prank(LP);
        quote.transfer(pairAddr, initLiq);
        vm.prank(LP);
        base.transfer(pairAddr, initLiq);
        vm.prank(LP);
        pair.mint(LP);
    }

    function _safeTokenTransfer(address token, address to, uint256 amount) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSignature("transfer(address,uint256)", to, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TRANSFER_FAILED");
    }

    function _safeTokenApprove(address token, address spender, uint256 amount) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSignature("approve(address,uint256)", spender, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "APPROVE_FAILED");
    }

    function _fundQuote(address to, uint256 amount) internal {
        MockERC20(monadQuoteToken).mint(to, amount);
    }

    function _fundBase(address to, uint256 amount) internal {
        MockERC20(monadBaseToken).mint(to, amount);
    }

    function _quoteBalance(address account) internal view returns (uint256) {
        return IERC20(monadQuoteToken).balanceOf(account);
    }

    function _baseBalance(address account) internal view returns (uint256) {
        return IERC20(monadBaseToken).balanceOf(account);
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

    function _buy(uint256 rawQuoteIn, uint256 baseOut, address trader) internal {
        _fundQuote(trader, rawQuoteIn);
        vm.prank(trader);
        _safeTokenTransfer(monadQuoteToken, address(pair), rawQuoteIn);

        if (_isQuote0()) {
            vm.prank(trader);
            pair.swap(0, baseOut, trader, new bytes(0));
        } else {
            vm.prank(trader);
            pair.swap(baseOut, 0, trader, new bytes(0));
        }
    }

    function _sell(uint256 baseIn, uint256 netQuoteOut, address trader) internal {
        _fundBase(trader, baseIn);
        vm.prank(trader);
        _safeTokenTransfer(monadBaseToken, address(pair), baseIn);

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

    function _path3(address a, address b, address c) internal pure returns (address[] memory p) {
        p = new address[](3);
        p[0] = a;
        p[1] = b;
        p[2] = c;
    }

    function _approveRouter(address token, address owner, uint256 amount) internal {
        vm.prank(owner);
        _safeTokenApprove(token, address(router), amount);
    }

    function _setVault(uint96 newVault) internal {
        uint256 slot = 14;
        uint256 packed = uint256(vm.load(address(pair), bytes32(slot)));
        uint256 lowMask = uint256(-1) >> 96;
        uint256 nextPacked = (packed & lowMask) | (uint256(newVault) << 160);
        vm.store(address(pair), bytes32(slot), bytes32(nextPacked));
    }

    function _setQuoteDisabled() internal {
        vm.prank(PAIR_ADMIN);
        factory.setQuoteToken(monadQuoteToken, false);
    }
}
