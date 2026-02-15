// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {NadSwapLensV1_1} from "../src/NadSwapLensV1_1.sol";

interface Vm {
    function envAddress(string calldata key) external returns (address);
    function envOr(string calldata key, address defaultValue) external returns (address);
    function startBroadcast() external;
    function stopBroadcast() external;
    function projectRoot() external view returns (string memory);
    function toString(address value) external pure returns (string memory);
    function toString(uint256 value) external pure returns (string memory);
    function writeFile(string calldata path, string calldata data) external;
}

contract DeployLensScript {
    Vm internal constant vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));

    function run() external returns (NadSwapLensV1_1 lens) {
        address factory = vm.envAddress("LENS_FACTORY");
        address router = vm.envOr("LENS_ROUTER", address(0));

        vm.startBroadcast();
        lens = new NadSwapLensV1_1(factory, router);
        vm.stopBroadcast();

        string memory outputPath = string.concat(vm.projectRoot(), "/../envs/deployed.lens.env");
        string memory envFile = string.concat(
            "export LENS_ADDRESS=", vm.toString(address(lens)), "\n",
            "export LENS_FACTORY=", vm.toString(factory), "\n",
            "export LENS_ROUTER=", vm.toString(router), "\n",
            "export LENS_CHAIN_ID=", vm.toString(block.chainid), "\n"
        );

        vm.writeFile(outputPath, envFile);
    }
}
