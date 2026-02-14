pragma solidity =0.5.16;

import "./MockERC20.sol";

contract MockWETH is MockERC20("Wrapped Ether", "WETH", 18) {
    event Deposit(address indexed dst, uint256 wad);
    event Withdrawal(address indexed src, uint256 wad);

    function() external payable {
        deposit();
    }

    function deposit() public payable {
        totalSupply += msg.value;
        balanceOf[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
        emit Transfer(address(0), msg.sender, msg.value);
    }

    function withdraw(uint256 wad) external {
        require(balanceOf[msg.sender] >= wad, "BALANCE");
        balanceOf[msg.sender] -= wad;
        totalSupply -= wad;
        emit Transfer(msg.sender, address(0), wad);
        msg.sender.transfer(wad);
        emit Withdrawal(msg.sender, wad);
    }
}
