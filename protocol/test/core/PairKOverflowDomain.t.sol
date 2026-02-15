pragma solidity =0.5.16;

import "./../helpers/PairFixture.sol";

contract PairKOverflowDomainTest is PairFixture {
    uint256 private constant LARGE_RESERVE_MIN = uint256(1) << 108;
    uint256 private constant LARGE_RESERVE_MAX = (uint256(1) << 111) - 1;

    function setUp() public {
        _setUpPair(300, 500);
    }

    function _setLargeSymmetricReserves(uint32 reserveSeed) internal {
        uint256 span = LARGE_RESERVE_MAX - LARGE_RESERVE_MIN + 1;
        uint256 target = LARGE_RESERVE_MIN + (uint256(reserveSeed) % span);

        (uint256 reserveQuote, uint256 reserveBase) = _reservesQuoteBase();
        if (target > reserveQuote) {
            _mintToken(quoteTokenAddr, address(pair), target - reserveQuote);
        }
        if (target > reserveBase) {
            _mintToken(baseTokenAddr, address(pair), target - reserveBase);
        }

        pair.sync();

        (uint256 syncedQuote, uint256 syncedBase) = _reservesQuoteBase();
        assertEq(syncedQuote, target, "quote reserve seed mismatch");
        assertEq(syncedBase, target, "base reserve seed mismatch");
    }

    function _bucketedAmount(uint256 baseAmount, uint8 bucket, uint256 seed) internal pure returns (uint256) {
        uint8 mode = bucket % 3;
        uint256 divisor = mode == 0 ? 1_000_000_000_000 : (mode == 1 ? 1_000_000 : 10);
        uint256 cap = baseAmount / divisor;
        if (cap == 0) cap = 1;
        return (seed % cap) + 1;
    }

    function _hugeBaseIn(uint64 seed, uint8 bucket) internal pure returns (uint256) {
        uint8 mode = bucket % 3;
        if (mode == 0) return (uint256(1) << 220) + uint256(seed);
        if (mode == 1) return (uint256(1) << 230) + (uint256(seed) << 16);
        return (uint256(1) << 240) + (uint256(seed) << 24);
    }

    function testFuzz_largeDomain_buy_kInvariant_holds(uint32 reserveSeed, uint256 amountSeed, uint8 bucket) public {
        _setLargeSymmetricReserves(reserveSeed);

        (uint256 reserveQuoteBefore, uint256 reserveBaseBefore) = _reservesQuoteBase();
        uint256 rawIn = _bucketedAmount(reserveQuoteBefore, bucket, amountSeed);

        uint256 maxRawIn = uint256(uint112(-1)) - reserveQuoteBefore - 1;
        if (rawIn > maxRawIn) rawIn = maxRawIn;
        uint256 maxRawInForVault = (uint256(uint96(-1)) * BPS) / pair.buyTaxBps();
        if (rawIn > maxRawInForVault) rawIn = maxRawInForVault;
        vm.assume(rawIn > 0);

        uint256 tax = rawIn * pair.buyTaxBps() / BPS;
        uint256 effIn = rawIn - tax;
        vm.assume(effIn > 0);

        uint256 baseOut = _getAmountOut(effIn, reserveQuoteBefore, reserveBaseBefore);
        vm.assume(baseOut > 0);

        uint256 kBefore = reserveQuoteBefore * reserveBaseBefore;

        _buy(rawIn, baseOut, TRADER);

        (uint256 reserveQuoteAfter, uint256 reserveBaseAfter) = _reservesQuoteBase();
        uint256 kAfter = reserveQuoteAfter * reserveBaseAfter;
        assertGe(kAfter, kBefore, "large-domain buy decreased K");
    }

    function testFuzz_largeDomain_sell_kInvariant_holds(uint32 reserveSeed, uint256 amountSeed, uint8 bucket) public {
        _setLargeSymmetricReserves(reserveSeed);

        (uint256 reserveQuoteBefore, uint256 reserveBaseBefore) = _reservesQuoteBase();
        uint256 sellCap = reserveQuoteBefore / 100;
        vm.assume(sellCap > 1);

        uint256 netQuoteOut = _bucketedAmount(sellCap, bucket, amountSeed);
        uint256 grossQuoteOut = _ceilDiv(netQuoteOut * BPS, BPS - pair.sellTaxBps());
        vm.assume(grossQuoteOut < reserveQuoteBefore);

        uint256 baseIn = _getAmountIn(grossQuoteOut, reserveBaseBefore, reserveQuoteBefore);
        uint256 maxBaseIn = uint256(uint112(-1)) - reserveBaseBefore - 1;
        vm.assume(baseIn > 0 && baseIn <= maxBaseIn);

        uint256 kBefore = reserveQuoteBefore * reserveBaseBefore;

        _sell(baseIn, netQuoteOut, TRADER);

        (uint256 reserveQuoteAfter, uint256 reserveBaseAfter) = _reservesQuoteBase();
        uint256 kAfter = reserveQuoteAfter * reserveBaseAfter;
        assertGe(kAfter, kBefore, "large-domain sell decreased K");
    }

    function testFuzz_largeAmount_sell_revertsWithKMultiplyOverflow(uint32 reserveSeed, uint64 hugeSeed, uint8 bucket)
        public
    {
        _setLargeSymmetricReserves(reserveSeed);

        uint256 hugeBaseIn = _hugeBaseIn(hugeSeed, bucket);
        _mintToken(baseTokenAddr, TRADER, hugeBaseIn);
        vm.prank(TRADER);
        _safeTokenTransfer(baseTokenAddr, address(pair), hugeBaseIn);

        bool quote0 = _isQuote0();
        expectRevertMsg("K_MULTIPLY_OVERFLOW");
        vm.prank(TRADER);
        if (quote0) {
            pair.swap(1, 0, TRADER, new bytes(0));
        } else {
            pair.swap(0, 1, TRADER, new bytes(0));
        }
    }
}
