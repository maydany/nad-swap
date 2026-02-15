// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

contract MockERC20 {
    string public name;
    string public symbol;
    uint8 public decimals;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    bool public revertBalanceOf;
    bool public revertAllowance;

    constructor(string memory _name, string memory _symbol, uint8 _decimals) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

    function setRevertBalanceOf(bool enabled) external {
        revertBalanceOf = enabled;
    }

    function setRevertAllowance(bool enabled) external {
        revertAllowance = enabled;
    }

    function mint(address to, uint256 amount) external {
        _balances[to] += amount;
    }

    function setAllowance(address owner, address spender, uint256 amount) external {
        _allowances[owner][spender] = amount;
    }

    function balanceOf(address owner) external view returns (uint256) {
        if (revertBalanceOf) revert("BALANCE_FAIL");
        return _balances[owner];
    }

    function allowance(address owner, address spender) external view returns (uint256) {
        if (revertAllowance) revert("ALLOWANCE_FAIL");
        return _allowances[owner][spender];
    }
}
