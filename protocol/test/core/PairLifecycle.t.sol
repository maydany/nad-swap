pragma solidity =0.5.16;

import "./../helpers/PairFixture.sol";
import "./../helpers/MockERC20.sol";

contract PairLifecycleTest is PairFixture {
    address internal constant LP2 = address(0x555);

    function setUp() public {
        _setUpPair(300, 500);
    }

    function _accrueVault() internal returns (uint256 vaultDelta) {
        (uint256 rq, uint256 rb) = _reservesQuoteBase();
        uint256 rawIn = 1000 ether;
        uint256 effIn = rawIn - (rawIn * pair.buyTaxBps() / BPS);
        uint256 baseOut = _getAmountOut(effIn, rq, rb);
        uint256 beforeVault = pair.accumulatedQuoteFees();
        _buy(rawIn, baseOut, TRADER);
        vaultDelta = pair.accumulatedQuoteFees() - beforeVault;
    }

    function test_mint_excludesVault() public {
        _accrueVault();
        (uint256 rqBefore, uint256 rbBefore) = _reservesQuoteBase();

        uint256 addQuote = 2000 ether;
        uint256 addBase = 2000 ether;
        _mintToken(quoteTokenAddr, LP2, addQuote);
        _mintToken(baseTokenAddr, LP2, addBase);
        vm.prank(LP2);
        _safeTokenTransfer(quoteTokenAddr, address(pair), addQuote);
        vm.prank(LP2);
        _safeTokenTransfer(baseTokenAddr, address(pair), addBase);
        vm.prank(LP2);
        pair.mint(LP2);

        (uint256 rqAfter, uint256 rbAfter) = _reservesQuoteBase();
        assertEq(rqAfter - rqBefore, addQuote, "mint included vault on quote side");
        assertEq(rbAfter - rbBefore, addBase, "mint base delta mismatch");
    }

    function test_burn_excludesVault() public {
        _accrueVault();
        (uint256 rqBefore, uint256 rbBefore) = _reservesQuoteBase();

        uint256 burnLiquidity = pair.balanceOf(LP) / 10;
        uint256 totalSupplyBefore = pair.totalSupply();
        uint256 expectedQuoteOut = burnLiquidity * rqBefore / totalSupplyBefore;
        uint256 expectedBaseOut = burnLiquidity * rbBefore / totalSupplyBefore;
        uint256 quoteBefore = _quoteBalance(LP);
        uint256 baseBefore = _baseBalance(LP);

        vm.prank(LP);
        pair.transfer(address(pair), burnLiquidity);
        vm.prank(LP);
        pair.burn(LP);

        uint256 quoteAfter = _quoteBalance(LP);
        uint256 baseAfter = _baseBalance(LP);
        assertEq(quoteAfter - quoteBefore, expectedQuoteOut, "burn included vault on quote payout");
        assertEq(baseAfter - baseBefore, expectedBaseOut, "burn base payout mismatch");
    }

    function test_mint_afterSwap_vaultIntact() public {
        _accrueVault();
        uint256 beforeVault = pair.accumulatedQuoteFees();

        _mintToken(quoteTokenAddr, LP2, 1000 ether);
        _mintToken(baseTokenAddr, LP2, 1000 ether);
        vm.prank(LP2);
        _safeTokenTransfer(quoteTokenAddr, address(pair), 1000 ether);
        vm.prank(LP2);
        _safeTokenTransfer(baseTokenAddr, address(pair), 1000 ether);
        vm.prank(LP2);
        pair.mint(LP2);

        assertEq(pair.accumulatedQuoteFees(), beforeVault, "vault changed on mint");
    }

    function test_burn_afterSwap_vaultIntact() public {
        _accrueVault();
        uint256 beforeVault = pair.accumulatedQuoteFees();

        uint256 burnLiquidity = pair.balanceOf(LP) / 20;
        vm.prank(LP);
        pair.transfer(address(pair), burnLiquidity);
        vm.prank(LP);
        pair.burn(LP);

        assertEq(pair.accumulatedQuoteFees(), beforeVault, "vault changed on burn");
    }

    function test_mint_vaultDrift_revert() public {
        (uint256 rawQuote,) = _rawQuoteBase();
        _setVault(uint96(rawQuote + 1));
        expectRevertMsg("VAULT_DRIFT");
        vm.prank(LP2);
        pair.mint(LP2);
    }

    function test_burn_vaultDrift_revert() public {
        (uint256 rawQuote,) = _rawQuoteBase();
        _setVault(uint96(rawQuote + 1));

        vm.prank(LP);
        expectRevertMsg("VAULT_DRIFT");
        pair.burn(LP);
    }

    function test_skim_underflow_safe() public {
        (uint256 rawQuote,) = _rawQuoteBase();
        _setVault(uint96(rawQuote));
        pair.skim(FEE_RECIPIENT);
    }

    function test_skim_excessDust_transfer() public {
        uint256 quoteDust = 7 ether;
        uint256 baseDust = 5 ether;
        _mintToken(quoteTokenAddr, address(pair), quoteDust);
        _mintToken(baseTokenAddr, address(pair), baseDust);

        uint256 quoteBefore = _quoteBalance(FEE_RECIPIENT);
        uint256 baseBefore = _baseBalance(FEE_RECIPIENT);
        pair.skim(FEE_RECIPIENT);
        uint256 quoteAfter = _quoteBalance(FEE_RECIPIENT);
        uint256 baseAfter = _baseBalance(FEE_RECIPIENT);

        assertEq(quoteAfter - quoteBefore, quoteDust, "quote dust skim mismatch");
        assertEq(baseAfter - baseBefore, baseDust, "base dust skim mismatch");
    }

    function test_sync_withVault_usesEffective() public {
        _accrueVault();
        _mintToken(quoteTokenAddr, address(pair), 11 ether);
        pair.sync();

        (uint256 reserveQuote,) = _reservesQuoteBase();
        (uint256 rawQuote,) = _rawQuoteBase();
        assertEq(reserveQuote, rawQuote - pair.accumulatedQuoteFees(), "sync did not store effective reserve");
    }

    function test_sync_afterClaim() public {
        _accrueVault();
        vm.prank(COLLECTOR);
        pair.claimQuoteFees(FEE_RECIPIENT);
        pair.sync();

        (uint256 reserveQuote,) = _reservesQuoteBase();
        (uint256 rawQuote,) = _rawQuoteBase();
        assertEq(pair.accumulatedQuoteFees(), 0, "vault not zero after claim");
        assertEq(reserveQuote, rawQuote, "sync after claim mismatch");
    }

    function test_sync_vaultDrift_revert() public {
        (uint256 rawQuote,) = _rawQuoteBase();
        _setVault(uint96(rawQuote + 1));
        expectRevertMsg("VAULT_DRIFT");
        pair.sync();
    }

    function test_firstDeposit_minimumLiquidity() public {
        MockERC20 q = new MockERC20("Quote2", "Q2", 18);
        MockERC20 b = new MockERC20("Base2", "B2", 18);
        UniswapV2Factory f = new UniswapV2Factory(FEE_TO_SETTER, PAIR_ADMIN);
        vm.prank(FEE_TO_SETTER);
        f.setQuoteToken(address(q), true);
        vm.prank(FEE_TO_SETTER);
        f.setBaseTokenSupported(address(b), true);

        vm.prank(PAIR_ADMIN);
        address pairAddr = f.createPair(address(q), address(b), 300, 500, COLLECTOR);
        UniswapV2Pair p = UniswapV2Pair(pairAddr);

        q.mint(LP2, 1_000_000 ether);
        b.mint(LP2, 1_000_000 ether);
        vm.prank(LP2);
        q.transfer(pairAddr, 1_000_000 ether);
        vm.prank(LP2);
        b.transfer(pairAddr, 1_000_000 ether);
        vm.prank(LP2);
        p.mint(LP2);

        assertEq(p.balanceOf(address(0)), p.MINIMUM_LIQUIDITY(), "minimum liquidity not burned");
    }
}
