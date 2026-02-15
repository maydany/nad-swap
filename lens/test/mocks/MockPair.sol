// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

contract MockPair {
    address public token0;
    address public token1;

    address public quoteToken;
    uint16 public buyTaxBps;
    uint16 public sellTaxBps;
    address public taxCollector;
    uint96 public accumulatedQuoteTax;

    uint112 private reserve0;
    uint112 private reserve1;
    uint32 private tsLast;

    uint256 public totalSupply;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    bool public revertAllowance;

    constructor(
        address _token0,
        address _token1,
        address _quoteToken,
        uint16 _buyTaxBps,
        uint16 _sellTaxBps,
        address _taxCollector
    ) {
        token0 = _token0;
        token1 = _token1;
        quoteToken = _quoteToken;
        buyTaxBps = _buyTaxBps;
        sellTaxBps = _sellTaxBps;
        taxCollector = _taxCollector;
    }

    function setReserves(uint112 r0, uint112 r1, uint32 t) external {
        reserve0 = r0;
        reserve1 = r1;
        tsLast = t;
    }

    function setAccumulatedQuoteTax(uint96 v) external {
        accumulatedQuoteTax = v;
    }

    function setBalance(address account, uint256 amount) external {
        _balances[account] = amount;
    }

    function setAllowance(address owner, address spender, uint256 amount) external {
        _allowances[owner][spender] = amount;
    }

    function setTotalSupply(uint256 amount) external {
        totalSupply = amount;
    }

    function setRevertAllowance(bool enabled) external {
        revertAllowance = enabled;
    }

    function getReserves() external view returns (uint112 r0, uint112 r1, uint32 ts) {
        return (reserve0, reserve1, tsLast);
    }

    function balanceOf(address owner) external view returns (uint256) {
        return _balances[owner];
    }

    function allowance(address owner, address spender) external view returns (uint256) {
        if (revertAllowance) revert("PAIR_ALLOWANCE_FAIL");
        return _allowances[owner][spender];
    }
}
