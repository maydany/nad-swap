// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {NadSwapLensV1_1} from "../src/NadSwapLensV1_1.sol";
import {TestBase08} from "./helpers/TestBase08.sol";
import {MockERC20} from "./mocks/MockERC20.sol";
import {MockFactory} from "./mocks/MockFactory.sol";
import {MockFactoryNoEnum} from "./mocks/MockFactoryNoEnum.sol";
import {MockPair} from "./mocks/MockPair.sol";

contract NadSwapLensV1_1Test is TestBase08 {
    address internal constant ROUTER = address(0xBEEF);
    address internal constant USER = address(0x1111);
    address internal constant COLLECTOR = address(0x2222);

    MockFactory internal factory;
    MockERC20 internal token0;
    MockERC20 internal token1;
    MockPair internal pair;
    MockPair internal pair2;
    MockPair internal pair3;
    NadSwapLensV1_1 internal lens;

    function setUp() public {
        factory = new MockFactory();
        token0 = new MockERC20("Quote", "QT", 18);
        token1 = new MockERC20("Base", "BS", 18);

        pair = new MockPair(address(token0), address(token1), address(token0), 300, 500, COLLECTOR);
        pair2 = new MockPair(address(token0), address(token1), address(token0), 100, 200, COLLECTOR);
        pair3 = new MockPair(address(token0), address(token1), address(token0), 150, 250, COLLECTOR);

        factory.setPair(address(pair), true);
        factory.setPair(address(pair2), true);
        factory.setPair(address(pair3), true);
        factory.setQuoteToken(address(token0), true);
        factory.setGetPair(address(token0), address(token1), address(pair));
        factory.setGetPair(address(token1), address(token0), address(pair));

        factory.pushAllPair(address(pair));
        factory.pushAllPair(address(pair2));
        factory.pushAllPair(address(pair3));

        pair.setReserves(1_000, 2_000, 12_345);
        pair.setAccumulatedQuoteTax(50);
        pair.setBalance(USER, 33);
        pair.setAllowance(USER, ROUTER, 333);

        token0.mint(address(pair), 1_060);
        token1.mint(address(pair), 2_007);
        token0.mint(USER, 500);
        token1.mint(USER, 700);
        token0.setAllowance(USER, ROUTER, 111);
        token1.setAllowance(USER, ROUTER, 222);

        lens = new NadSwapLensV1_1(address(factory), ROUTER);
    }

    function test_getPair_zeroWhenMissing() public view {
        (address found, bool valid) = lens.getPair(address(token0), address(0x9999));
        assertEq(found, address(0), "pair should be zero");
        assertEq(valid, false, "valid should be false");
    }

    function test_getPair_validAndInvalidBranches() public {
        (address found, bool valid) = lens.getPair(address(token0), address(token1));
        assertEq(found, address(pair), "valid pair mismatch");
        assertEq(valid, true, "valid flag mismatch");

        address fakePair = address(0x7777);
        factory.setGetPair(address(token0), address(0x1234), fakePair);

        (found, valid) = lens.getPair(address(token0), address(0x1234));
        assertEq(found, fakePair, "invalid pair address mismatch");
        assertEq(valid, false, "invalid branch should be false");
    }

    function test_getPairStatic_invalidPair() public view {
        NadSwapLensV1_1.PairStatic memory s = lens.getPairStatic(address(0xABCD));

        assertEq(s.status, uint8(1), "status should be invalid");
        assertEq(s.pair, address(0xABCD), "pair mismatch");
        assertEq(s.lpFeeBps, uint16(20), "lp fee mismatch");
    }

    function test_getPairStatic_validFields() public view {
        NadSwapLensV1_1.PairStatic memory s = lens.getPairStatic(address(pair));

        assertEq(s.status, uint8(0), "status should be ok");
        assertEq(s.token0, address(token0), "token0 mismatch");
        assertEq(s.token1, address(token1), "token1 mismatch");
        assertEq(s.quoteToken, address(token0), "quote mismatch");
        assertEq(s.baseToken, address(token1), "base mismatch");
        assertEq(s.isQuote0, true, "isQuote0 mismatch");
        assertEq(s.isQuoteSupported, true, "quote support mismatch");
        assertEq(s.buyTaxBps, uint16(300), "buy tax mismatch");
        assertEq(s.sellTaxBps, uint16(500), "sell tax mismatch");
        assertEq(s.taxCollector, COLLECTOR, "collector mismatch");
        assertEq(s.lpFeeBps, uint16(20), "lp fee mismatch");
    }

    function test_getPairDynamic_validAccounting() public view {
        NadSwapLensV1_1.PairDynamic memory d = lens.getPairDynamic(address(pair));

        assertEq(d.status, uint8(0), "status should be ok");
        assertEq(d.reserve0Eff, uint112(1_000), "reserve0 mismatch");
        assertEq(d.reserve1Eff, uint112(2_000), "reserve1 mismatch");
        assertEq(d.blockTimestampLast, uint32(12_345), "timestamp mismatch");
        assertEq(d.raw0, 1_060, "raw0 mismatch");
        assertEq(d.raw1, 2_007, "raw1 mismatch");
        assertEq(d.vaultQuote, uint96(50), "vault mismatch");
        assertEq(d.rawQuote, 1_060, "raw quote mismatch");
        assertEq(d.rawBase, 2_007, "raw base mismatch");
        assertEq(d.expectedQuoteRaw, 1_050, "expected quote mismatch");
        assertEq(d.expectedBaseRaw, 2_000, "expected base mismatch");
        assertEq(d.dustQuote, 10, "quote dust mismatch");
        assertEq(d.dustBase, 7, "base dust mismatch");
        assertEq(d.vaultDrift, false, "vault drift mismatch");
    }

    function test_getPairDynamic_degradedWhenBalanceReadFails() public {
        token0.setRevertBalanceOf(true);

        NadSwapLensV1_1.PairDynamic memory d = lens.getPairDynamic(address(pair));
        assertEq(d.status, uint8(2), "status should be degraded");
        assertEq(d.raw0, 0, "raw0 should be zero when read fails");
        assertEq(d.raw1, 2_007, "raw1 mismatch");
        assertEq(d.vaultDrift, true, "vault drift should be true");
    }

    function test_getUserState_userZero() public view {
        NadSwapLensV1_1.UserState memory u = lens.getUserState(address(pair), address(0));
        assertEq(u.status, uint8(2), "status should be degraded for zero user");
    }

    function test_getUserState_invalidPair() public view {
        NadSwapLensV1_1.UserState memory u = lens.getUserState(address(0xDEAD), USER);
        assertEq(u.status, uint8(1), "status should be invalid pair");
    }

    function test_getUserState_routerZeroStatusOk() public {
        NadSwapLensV1_1 lensNoRouter = new NadSwapLensV1_1(address(factory), address(0));
        NadSwapLensV1_1.UserState memory u = lensNoRouter.getUserState(address(pair), USER);

        assertEq(u.status, uint8(0), "status should be ok");
        assertEq(u.token0Balance, 500, "token0 balance mismatch");
        assertEq(u.token1Balance, 700, "token1 balance mismatch");
        assertEq(u.lpBalance, 33, "lp balance mismatch");
        assertEq(u.token0AllowanceToRouter, 0, "allowance should remain zero");
        assertEq(u.token1AllowanceToRouter, 0, "allowance should remain zero");
        assertEq(u.lpAllowanceToRouter, 0, "allowance should remain zero");
    }

    function test_getUserState_degradedWhenAllowanceFails() public {
        token1.setRevertAllowance(true);

        NadSwapLensV1_1.UserState memory u = lens.getUserState(address(pair), USER);
        assertEq(u.status, uint8(2), "status should be degraded");
        assertEq(u.token0Balance, 500, "token0 balance mismatch");
        assertEq(u.token1Balance, 700, "token1 balance mismatch");
        assertEq(u.lpBalance, 33, "lp balance mismatch");
        assertEq(u.token0AllowanceToRouter, 111, "token0 allowance mismatch");
        assertEq(u.token1AllowanceToRouter, 0, "token1 allowance should be zero on failure");
        assertEq(u.lpAllowanceToRouter, 333, "lp allowance mismatch");
    }

    function test_getPairView_returnsConsistentTriplet() public view {
        (
            NadSwapLensV1_1.PairStatic memory s,
            NadSwapLensV1_1.PairDynamic memory d,
            NadSwapLensV1_1.UserState memory u
        ) = lens.getPairView(address(pair), USER);

        assertEq(s.status, uint8(0), "static status mismatch");
        assertEq(d.status, uint8(0), "dynamic status mismatch");
        assertEq(u.status, uint8(0), "user status mismatch");
        assertEq(s.quoteToken, address(token0), "quote mismatch");
        assertEq(d.expectedQuoteRaw, 1_050, "expected quote mismatch");
        assertEq(u.token0AllowanceToRouter, 111, "allowance mismatch");
    }

    function test_getPairsLength_falseWhenFactoryHasNoEnumeration() public {
        MockFactoryNoEnum noEnumFactory = new MockFactoryNoEnum();
        NadSwapLensV1_1 lensNoEnum = new NadSwapLensV1_1(address(noEnumFactory), ROUTER);

        (bool ok, uint256 len) = lensNoEnum.getPairsLength();
        assertEq(ok, false, "ok should be false");
        assertEq(len, 0, "len should be zero");
    }

    function test_getPairsPage_paginationAndOutOfRange() public view {
        (bool ok, address[] memory page) = lens.getPairsPage(1, 2);
        assertEq(ok, true, "ok should be true");
        assertEq(page.length, 2, "page length mismatch");
        assertEq(page[0], address(pair2), "page[0] mismatch");
        assertEq(page[1], address(pair3), "page[1] mismatch");

        (ok, page) = lens.getPairsPage(3, 10);
        assertEq(ok, true, "ok should be true");
        assertEq(page.length, 0, "page should be empty");
    }

    function test_getPairsPage_revertWhenCountTooLarge() public {
        uint256 tooLarge = lens.MAX_BATCH() + 1;
        expectRevertMsg("COUNT_TOO_LARGE");
        lens.getPairsPage(0, tooLarge);
    }

    function test_getPairsPage_falseWhenAllPairsIndexFails() public {
        factory.setFailAllPairs(true, 1);

        (bool ok, address[] memory page) = lens.getPairsPage(0, 2);
        assertEq(ok, false, "ok should be false");
        assertEq(page.length, 0, "page should be empty");
    }

    function test_getPairsStaticAndDynamic_mixedValidityAndBatchLimit() public {
        address[] memory twoPairs = new address[](2);
        twoPairs[0] = address(pair);
        twoPairs[1] = address(0xDEAD);

        NadSwapLensV1_1.PairStatic[] memory statics = lens.getPairsStatic(twoPairs);
        assertEq(statics.length, 2, "static length mismatch");
        assertEq(statics[0].status, uint8(0), "static[0] status mismatch");
        assertEq(statics[1].status, uint8(1), "static[1] status mismatch");

        NadSwapLensV1_1.PairDynamic[] memory dynamics = lens.getPairsDynamic(twoPairs);
        assertEq(dynamics.length, 2, "dynamic length mismatch");
        assertEq(dynamics[0].status, uint8(0), "dynamic[0] status mismatch");
        assertEq(dynamics[1].status, uint8(1), "dynamic[1] status mismatch");

        uint256 tooLarge = lens.MAX_BATCH() + 1;
        address[] memory large = new address[](tooLarge);

        expectRevertMsg("BATCH_TOO_LARGE");
        lens.getPairsStatic(large);

        expectRevertMsg("BATCH_TOO_LARGE");
        lens.getPairsDynamic(large);
    }
}
