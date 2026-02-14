pragma solidity =0.5.16;

interface Vm {
    function prank(address) external;
    function expectRevert(bytes calldata) external;
    function expectEmit(bool checkTopic1, bool checkTopic2, bool checkTopic3, bool checkData) external;
    function expectEmit(bool checkTopic1, bool checkTopic2, bool checkTopic3, bool checkData, address emitter)
        external;
    function warp(uint256) external;
    function assume(bool) external;
    function load(address target, bytes32 slot) external view returns (bytes32);
    function store(address target, bytes32 slot, bytes32 value) external;
    function createSelectFork(string calldata urlOrAlias) external returns (uint256);
    function createSelectFork(string calldata urlOrAlias, uint256 blockNumber) external returns (uint256);
    function selectFork(uint256 forkId) external;
    function envAddress(string calldata key) external returns (address);
    function envUint(string calldata key) external returns (uint256);
    function envString(string calldata key) external returns (string memory);
    function envOr(string calldata key, uint256 defaultValue) external returns (uint256);
}

contract TestBase {
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

    function assertGt(uint256 a, uint256 b, string memory message) internal pure {
        require(a > b, message);
    }

    function assertGe(uint256 a, uint256 b, string memory message) internal pure {
        require(a >= b, message);
    }

    function assertLt(uint256 a, uint256 b, string memory message) internal pure {
        require(a < b, message);
    }

    function assertLe(uint256 a, uint256 b, string memory message) internal pure {
        require(a <= b, message);
    }

    function expectRevertMsg(string memory reason) internal {
        vm.expectRevert(bytes(reason));
    }
}
