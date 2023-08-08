// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {FromL1ControlL2} from "../src/FromL1ControlL2.sol";
import {DeployCrossChainNFT} from "./DeployCrossChainNFT.s.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {AddConsumer, CreateSubscription, FundSubscription} from "./Interactions.s.sol";

contract DeployFromL1ControlL2 is Script {
    function run() external returns (FromL1ControlL2, HelperConfig, address) {
        // Create a new instance of the HelperConfig contract
        HelperConfig helperConfig = new HelperConfig();
        AddConsumer addConsumer;
        address crossChainNFTL1Addr;
        // Get the address of the CrossChainNFT contract deployed on Layer 1 (Goerli testnet)
        if (block.chainid == 31337) {
            DeployCrossChainNFT deployer = new DeployCrossChainNFT();
            crossChainNFTL1Addr = address(deployer.run());
        } else {
            crossChainNFTL1Addr = vm.envAddress("GOERLI_CROSSCHAINNFT");
        }
        // Get the addresses of the CrossChainNFT contracts deployed on Layer 2
        address[3] memory crossChainNFTL2Addr = [
            vm.envAddress("OP_CROSSCHAINNFT"),
            vm.envAddress("BASE_CROSSCHAINNFT"),
            vm.envAddress("ZORA_CROSSCHAINNFT")
        ];
        // Get the password from the environment variable
        uint256 password = vm.envUint("PASSWORD");
        // Get the VRF subscription details from the active network configuration in the HelperConfig contract
        (
            uint64 subscriptionId,
            bytes32 gasLane,
            uint32 callbackGasLimit,
            address vrfCoordinatorV2,
            address link,
            uint256 deployerKey
        ) = helperConfig.activeNetworkConfig();
        // If there is no existing VRF subscription, create and fund a new one
        if (subscriptionId == 0) {
            CreateSubscription createSubscription = new CreateSubscription();
            subscriptionId = createSubscription.createSubscription(
                vrfCoordinatorV2,
                deployerKey
            );

            FundSubscription fundSubscription = new FundSubscription();
            fundSubscription.fundSubscription(
                vrfCoordinatorV2,
                subscriptionId,
                link,
                deployerKey
            );
        }
        // Start broadcasting the transaction with the deployer's private key
        vm.startBroadcast(deployerKey);
        // Deploy the FromL1ControlL2 contract with the specified parameters
        FromL1ControlL2 fromL1ControlL2 = new FromL1ControlL2(
            crossChainNFTL1Addr,
            crossChainNFTL2Addr,
            password,
            vrfCoordinatorV2,
            subscriptionId,
            gasLane,
            callbackGasLimit
        );
        vm.stopBroadcast();
        // If the current chain ID is 31337 (local development network), add the FromL1ControlL2 contract as a consumer of the VRF subscription
        if (block.chainid == 31337) {
            addConsumer = new AddConsumer();
            addConsumer.addConsumer(
                address(fromL1ControlL2),
                vrfCoordinatorV2,
                subscriptionId,
                deployerKey
            );
        }
        // Return the deployed FromL1ControlL2 contract instance and HelperConfig contract instance
        return (fromL1ControlL2, helperConfig, crossChainNFTL1Addr);
    }
}
