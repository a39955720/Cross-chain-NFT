// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {CrossChainNFT} from "../src/CrossChainNFT.sol";

contract DeployCrossChainNFT is Script {
    function run() external returns (CrossChainNFT) {
        string[3] memory ccnTokenUris = [
            "ipfs://QmYZ8GkP5NamhgmdZHomfiFQqizG2cY3UWBNV5RNKuapuy",
            "ipfs://QmXs5UeXttXRAe6eMM6h7mwGL2mxDcUqgXcqacH79JMPPK",
            "ipfs://QmSqjLJSfLjuDd8ENYigTNtrcb89Modm95kR4w8jb57dqP"
        ];
        uint256 password = vm.envUint("PASSWORD");
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerKey);
        CrossChainNFT crossChainNFT = new CrossChainNFT(ccnTokenUris, password);
        vm.stopBroadcast();
        return crossChainNFT;
    }
}
