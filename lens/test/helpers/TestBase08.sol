// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

interface Vm {
    function prank(address) external;
    function expectRevert(bytes calldata) external;
    function createSelectFork(string calldata urlOrAlias) external returns (uint256);
    function createSelectFork(string calldata urlOrAlias, uint256 blockNumber) external returns (uint256);
    function envAddress(string calldata key) external returns (address);
    function envUint(string calldata key) external returns (uint256);
    function envString(string calldata key) external returns (string memory);
    function envOr(string calldata key, uint256 defaultValue) external returns (uint256);
}

contract TestBase08 {
    Vm internal constant vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));

    function assertTrue(bool cond, string memory message) internal pure {
        require(cond, message);
    }

    function assertEq(uint256 a, uint256 b, string memory message) internal pure {
        require(a == b, message);
    }

    function assertEq(address a, address b, string memory message) internal pure {
        require(a == b, message);
    }

    function assertEq(bool a, bool b, string memory message) internal pure {
        require(a == b, message);
    }

    function expectRevertMsg(string memory reason) internal {
        vm.expectRevert(bytes(reason));
    }
}
