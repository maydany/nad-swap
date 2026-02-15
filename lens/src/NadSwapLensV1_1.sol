// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

/// @notice Minimal ERC20 read interface.
interface IERC20Minimal {
    function balanceOf(address) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
}

/// @notice Minimal factory interface consumed by the lens.
interface INadSwapV2FactoryMinimal {
    function isPair(address pair) external view returns (bool);
    function isQuoteToken(address token) external view returns (bool);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

/// @notice Minimal pair interface consumed by the lens.
interface INadSwapV2PairMinimal {
    function token0() external view returns (address);
    function token1() external view returns (address);

    function quoteToken() external view returns (address);
    function buyTaxBps() external view returns (uint16);
    function sellTaxBps() external view returns (uint16);
    function taxCollector() external view returns (address);
    function accumulatedQuoteTax() external view returns (uint96);

    function getReserves() external view returns (uint112 r0, uint112 r1, uint32 tsLast);

    function totalSupply() external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
}

/// @title NadSwap Lens v1.1
/// @notice Read-only helper for NadSwap V2 pairs and user-level portfolio state.
/// @dev Compiled with Solidity 0.8.x while targeting Cancun-compatible opcodes.
contract NadSwapLensV1_1 {
    INadSwapV2FactoryMinimal public immutable factory;
    address public immutable router;

    uint16 public constant LP_FEE_BPS = 20;
    uint256 public constant MAX_BATCH = 200;

    bytes4 internal constant SEL_ALL_PAIRS_LENGTH = bytes4(keccak256("allPairsLength()"));
    bytes4 internal constant SEL_ALL_PAIRS = bytes4(keccak256("allPairs(uint256)"));

    uint8 internal constant STATUS_OK = 0;
    uint8 internal constant STATUS_INVALID_PAIR = 1;
    uint8 internal constant STATUS_DEGRADED = 2;

    struct PairStatic {
        uint8 status;
        address pair;

        address token0;
        address token1;

        address quoteToken;
        address baseToken;
        bool isQuote0;

        bool isQuoteSupported;

        uint16 buyTaxBps;
        uint16 sellTaxBps;
        address taxCollector;

        uint16 lpFeeBps;
    }

    struct PairDynamic {
        uint8 status;
        address pair;

        uint112 reserve0Eff;
        uint112 reserve1Eff;
        uint32 blockTimestampLast;

        uint256 raw0;
        uint256 raw1;

        uint96 vaultQuote;

        uint256 rawQuote;
        uint256 rawBase;

        uint256 expectedQuoteRaw;
        uint256 expectedBaseRaw;

        uint256 dustQuote;
        uint256 dustBase;

        bool vaultDrift;
    }

    struct UserState {
        uint8 status;
        address pair;
        address user;

        address token0;
        address token1;

        uint256 token0Balance;
        uint256 token1Balance;
        uint256 lpBalance;

        uint256 token0AllowanceToRouter;
        uint256 token1AllowanceToRouter;
        uint256 lpAllowanceToRouter;
    }

    struct AccountingValues {
        uint256 rawQuote;
        uint256 rawBase;
        uint256 expectedQuoteRaw;
        uint256 expectedBaseRaw;
        uint256 dustQuote;
        uint256 dustBase;
        bool vaultDrift;
    }

    constructor(address _factory, address _router) {
        require(_factory != address(0), "ZERO_FACTORY");
        factory = INadSwapV2FactoryMinimal(_factory);
        router = _router;
    }

    function _safeStaticCallUint(address target, bytes4 selector, bytes memory args)
        internal
        view
        returns (bool ok, uint256 val)
    {
        (bool success, bytes memory data) = target.staticcall(abi.encodePacked(selector, args));
        if (!success || data.length < 32) return (false, 0);
        val = abi.decode(data, (uint256));
        return (true, val);
    }

    function _safeBalanceOf(address token, address owner) internal view returns (bool ok, uint256 bal) {
        (bool success, bytes memory data) = token.staticcall(
            abi.encodeWithSelector(IERC20Minimal.balanceOf.selector, owner)
        );
        if (!success || data.length < 32) return (false, 0);
        bal = abi.decode(data, (uint256));
        return (true, bal);
    }

    function _safeAllowance(address token, address owner, address spender)
        internal
        view
        returns (bool ok, uint256 amt)
    {
        (bool success, bytes memory data) = token.staticcall(
            abi.encodeWithSelector(IERC20Minimal.allowance.selector, owner, spender)
        );
        if (!success || data.length < 32) return (false, 0);
        amt = abi.decode(data, (uint256));
        return (true, amt);
    }

    function _computePairAccounting(
        bool isQ0,
        uint112 r0,
        uint112 r1,
        uint256 raw0,
        uint256 raw1,
        uint96 vault
    )
        internal
        pure
        returns (AccountingValues memory a)
    {
        uint256 reserveQuoteEff = isQ0 ? uint256(r0) : uint256(r1);
        uint256 reserveBaseEff = isQ0 ? uint256(r1) : uint256(r0);

        a.rawQuote = isQ0 ? raw0 : raw1;
        a.rawBase = isQ0 ? raw1 : raw0;

        a.expectedQuoteRaw = reserveQuoteEff + uint256(vault);
        a.expectedBaseRaw = reserveBaseEff;

        a.dustQuote = a.rawQuote > a.expectedQuoteRaw ? (a.rawQuote - a.expectedQuoteRaw) : 0;
        a.dustBase = a.rawBase > a.expectedBaseRaw ? (a.rawBase - a.expectedBaseRaw) : 0;

        a.vaultDrift = (a.rawQuote < uint256(vault));
    }

    function getPair(address tokenA, address tokenB) external view returns (address pair, bool isValidPair) {
        pair = factory.getPair(tokenA, tokenB);
        if (pair == address(0)) return (address(0), false);
        isValidPair = factory.isPair(pair);
    }

    function getPairStatic(address pair) public view returns (PairStatic memory s) {
        s.lpFeeBps = LP_FEE_BPS;
        s.pair = pair;

        if (!factory.isPair(pair)) {
            s.status = STATUS_INVALID_PAIR;
            return s;
        }

        INadSwapV2PairMinimal p = INadSwapV2PairMinimal(pair);

        address t0 = p.token0();
        address t1 = p.token1();
        address qt = p.quoteToken();
        bool isQ0 = (qt == t0);

        s.token0 = t0;
        s.token1 = t1;
        s.quoteToken = qt;
        s.isQuote0 = isQ0;
        s.baseToken = isQ0 ? t1 : t0;

        s.buyTaxBps = p.buyTaxBps();
        s.sellTaxBps = p.sellTaxBps();
        s.taxCollector = p.taxCollector();

        s.isQuoteSupported = factory.isQuoteToken(qt);

        s.status = STATUS_OK;
    }

    function getPairDynamic(address pair) public view returns (PairDynamic memory d) {
        d.pair = pair;

        if (!factory.isPair(pair)) {
            d.status = STATUS_INVALID_PAIR;
            return d;
        }

        INadSwapV2PairMinimal p = INadSwapV2PairMinimal(pair);

        (uint112 r0, uint112 r1, uint32 ts) = p.getReserves();
        d.reserve0Eff = r0;
        d.reserve1Eff = r1;
        d.blockTimestampLast = ts;

        bool isQ0;
        {
            address t0 = p.token0();
            address t1 = p.token1();
            isQ0 = (p.quoteToken() == t0);

            (bool ok0, uint256 raw0) = _safeBalanceOf(t0, pair);
            (bool ok1, uint256 raw1) = _safeBalanceOf(t1, pair);

            d.raw0 = raw0;
            d.raw1 = raw1;
            d.status = (ok0 && ok1) ? STATUS_OK : STATUS_DEGRADED;
        }

        uint96 vault = p.accumulatedQuoteTax();
        d.vaultQuote = vault;

        AccountingValues memory a = _computePairAccounting(isQ0, r0, r1, d.raw0, d.raw1, vault);
        d.rawQuote = a.rawQuote;
        d.rawBase = a.rawBase;
        d.expectedQuoteRaw = a.expectedQuoteRaw;
        d.expectedBaseRaw = a.expectedBaseRaw;
        d.dustQuote = a.dustQuote;
        d.dustBase = a.dustBase;
        d.vaultDrift = a.vaultDrift;
    }

    function getUserState(address pair, address user) public view returns (UserState memory u) {
        u.pair = pair;
        u.user = user;

        if (user == address(0)) {
            u.status = STATUS_DEGRADED;
            return u;
        }

        if (!factory.isPair(pair)) {
            u.status = STATUS_INVALID_PAIR;
            return u;
        }

        INadSwapV2PairMinimal p = INadSwapV2PairMinimal(pair);
        address t0 = p.token0();
        address t1 = p.token1();

        u.token0 = t0;
        u.token1 = t1;

        (, u.token0Balance) = _safeBalanceOf(t0, user);
        (, u.token1Balance) = _safeBalanceOf(t1, user);
        (, u.lpBalance) = _safeBalanceOf(pair, user);

        if (router != address(0)) {
            (bool a0, uint256 al0) = _safeAllowance(t0, user, router);
            (bool a1, uint256 al1) = _safeAllowance(t1, user, router);
            (bool alp, uint256 allp) = _safeAllowance(pair, user, router);

            u.token0AllowanceToRouter = al0;
            u.token1AllowanceToRouter = al1;
            u.lpAllowanceToRouter = allp;

            u.status = (a0 && a1 && alp) ? STATUS_OK : STATUS_DEGRADED;
        } else {
            u.status = STATUS_OK;
        }
    }

    function getPairView(address pair, address user)
        external
        view
        returns (PairStatic memory s, PairDynamic memory d, UserState memory u)
    {
        s = getPairStatic(pair);
        d = getPairDynamic(pair);
        u = getUserState(pair, user);
    }

    function getPairsLength() external view returns (bool ok, uint256 len) {
        (ok, len) = _safeStaticCallUint(address(factory), SEL_ALL_PAIRS_LENGTH, bytes(""));
    }

    function getPairsPage(uint256 start, uint256 count)
        external
        view
        returns (bool ok, address[] memory pairs)
    {
        require(count <= MAX_BATCH, "COUNT_TOO_LARGE");

        (bool okLen, uint256 len) = _safeStaticCallUint(address(factory), SEL_ALL_PAIRS_LENGTH, bytes(""));
        if (!okLen) return (false, new address[](0));
        if (start >= len) return (true, new address[](0));

        uint256 n = count;
        if (start + n > len) n = len - start;

        pairs = new address[](n);

        for (uint256 i = 0; i < n;) {
            uint256 idx = start + i;
            // allPairs(uint256)
            (bool success, bytes memory data) = address(factory).staticcall(
                abi.encodeWithSelector(SEL_ALL_PAIRS, idx)
            );
            if (!success || data.length < 32) {
                return (false, new address[](0));
            }
            pairs[i] = abi.decode(data, (address));
            unchecked {
                ++i;
            }
        }

        return (true, pairs);
    }

    function getPairsStatic(address[] calldata pairs) external view returns (PairStatic[] memory out) {
        uint256 n = pairs.length;
        require(n <= MAX_BATCH, "BATCH_TOO_LARGE");

        out = new PairStatic[](n);
        for (uint256 i = 0; i < n;) {
            out[i] = getPairStatic(pairs[i]);
            unchecked {
                ++i;
            }
        }
    }

    function getPairsDynamic(address[] calldata pairs) external view returns (PairDynamic[] memory out) {
        uint256 n = pairs.length;
        require(n <= MAX_BATCH, "BATCH_TOO_LARGE");

        out = new PairDynamic[](n);
        for (uint256 i = 0; i < n;) {
            out[i] = getPairDynamic(pairs[i]);
            unchecked {
                ++i;
            }
        }
    }
}
