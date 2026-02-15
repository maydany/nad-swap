// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {NadSwapLensV1_1} from "../../src/NadSwapLensV1_1.sol";
import {TestBase08} from "../helpers/TestBase08.sol";
import {MockERC20} from "../mocks/MockERC20.sol";
import {MockFactory} from "../mocks/MockFactory.sol";
import {MockPair} from "../mocks/MockPair.sol";

contract NadSwapLensForkSmokeTest is TestBase08 {
    address internal constant ROUTER = address(0xBEEF);
    address internal constant USER = address(0x1111);
    address internal constant COLLECTOR = address(0x2222);

    bool internal forkEnabled;

    MockFactory internal factory;
    MockERC20 internal token0;
    MockERC20 internal token1;
    MockPair internal pair;
    NadSwapLensV1_1 internal lens;

    modifier onlyFork() {
        require(forkEnabled, "FORK_NOT_ENABLED");
        _;
    }

    function setUp() public {
        forkEnabled = vm.envOr("MONAD_FORK_ENABLED", uint256(0)) == 1;
        if (!forkEnabled) return;

        string memory rpcUrl = vm.envString("MONAD_RPC_URL");
        uint256 forkBlock = vm.envOr("MONAD_FORK_BLOCK", uint256(0));
        if (forkBlock == 0) {
            vm.createSelectFork(rpcUrl);
        } else {
            vm.createSelectFork(rpcUrl, forkBlock);
        }

        factory = new MockFactory();
        token0 = new MockERC20("ForkQuote", "FQ", 18);
        token1 = new MockERC20("ForkBase", "FB", 18);
        pair = new MockPair(address(token0), address(token1), address(token0), 300, 500, COLLECTOR);

        factory.setPair(address(pair), true);
        factory.setQuoteToken(address(token0), true);
        factory.setGetPair(address(token0), address(token1), address(pair));
        factory.pushAllPair(address(pair));

        pair.setReserves(1_000, 2_000, 55_555);
        pair.setAccumulatedQuoteTax(50);
        pair.setBalance(USER, 9);
        pair.setAllowance(USER, ROUTER, 99);

        token0.mint(address(pair), 1_050);
        token1.mint(address(pair), 2_000);
        token0.mint(USER, 10);
        token1.mint(USER, 20);
        token0.setAllowance(USER, ROUTER, 11);
        token1.setAllowance(USER, ROUTER, 22);

        lens = new NadSwapLensV1_1(address(factory), ROUTER);
    }

    function test_forkSmoke_nonRevertingReadPaths() public onlyFork {
        (address foundPair, bool isValidPair) = lens.getPair(address(token0), address(token1));
        assertEq(foundPair, address(pair), "pair mismatch");
        assertEq(isValidPair, true, "pair should be valid");

        NadSwapLensV1_1.PairStatic memory s = lens.getPairStatic(address(pair));
        NadSwapLensV1_1.PairDynamic memory d = lens.getPairDynamic(address(pair));
        NadSwapLensV1_1.UserState memory u = lens.getUserState(address(pair), USER);
        (NadSwapLensV1_1.PairStatic memory vs, NadSwapLensV1_1.PairDynamic memory vd, NadSwapLensV1_1.UserState memory vu)
        = lens.getPairView(address(pair), USER);

        assertEq(s.status, uint8(0), "static status mismatch");
        assertEq(d.status, uint8(0), "dynamic status mismatch");
        assertEq(u.status, uint8(0), "user status mismatch");
        assertEq(vs.status, uint8(0), "view static status mismatch");
        assertEq(vd.status, uint8(0), "view dynamic status mismatch");
        assertEq(vu.status, uint8(0), "view user status mismatch");

        (bool okLength, uint256 len) = lens.getPairsLength();
        assertEq(okLength, true, "pairs length should be ok");
        assertEq(len, 1, "pairs length mismatch");

        (bool okPage, address[] memory page) = lens.getPairsPage(0, 1);
        assertEq(okPage, true, "pairs page should be ok");
        assertEq(page.length, 1, "pairs page length mismatch");
        assertEq(page[0], address(pair), "pairs page item mismatch");

        address[] memory query = new address[](1);
        query[0] = address(pair);

        NadSwapLensV1_1.PairStatic[] memory statics = lens.getPairsStatic(query);
        NadSwapLensV1_1.PairDynamic[] memory dynamics = lens.getPairsDynamic(query);
        assertEq(statics.length, 1, "batch static length mismatch");
        assertEq(dynamics.length, 1, "batch dynamic length mismatch");
        assertEq(statics[0].status, uint8(0), "batch static status mismatch");
        assertEq(dynamics[0].status, uint8(0), "batch dynamic status mismatch");
    }
}
