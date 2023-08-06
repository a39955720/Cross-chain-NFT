// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {FromL2ControlL1} from "../src/FromL2ControlL1.sol";

contract DeployCrossChainNFT is Script {
    function run() external returns (FromL2ControlL1) {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        address l1Controller = vm.envAddress("L1Controller");

        if (block.chainid == 31337) {
            deployerKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
        }

        // Start broadcasting the transaction with the deployer's private key
        vm.startBroadcast(deployerKey);
        FromL2ControlL1 fromL2ControlL1 = new FromL2ControlL1(l1Controller);
        vm.stopBroadcast();

        // Return the deployed FromL2ControlL1 contract instance
        return fromL2ControlL1;
    }
}
