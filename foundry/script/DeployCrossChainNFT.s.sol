// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {CrossChainNFT} from "../src/CrossChainNFT.sol";

contract DeployCrossChainNFT is Script {
    function run() external returns (CrossChainNFT) {
        // Define an array of IPFS URIs for the CCN token Uris
        string[3] memory ccnTokenUris = [
            "ipfs://QmYZ8GkP5NamhgmdZHomfiFQqizG2cY3UWBNV5RNKuapuy",
            "ipfs://QmXs5UeXttXRAe6eMM6h7mwGL2mxDcUqgXcqacH79JMPPK",
            "ipfs://QmSqjLJSfLjuDd8ENYigTNtrcb89Modm95kR4w8jb57dqP"
        ];
        // Get the password and private key from the environment variables
        uint256 password = vm.envUint("PASSWORD");
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        if (block.chainid == 31337) {
            deployerKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
        }

        // Start broadcasting the transaction with the deployer's private key
        vm.startBroadcast(deployerKey);
        CrossChainNFT crossChainNFT = new CrossChainNFT(ccnTokenUris, password);
        vm.stopBroadcast();

        // Return the deployed CrossChainNFT contract instance
        return crossChainNFT;
    }
}
