// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {CrossChainNFT} from "../src/CrossChainNFT.sol";
import {DeployCrossChainNFT} from "./DeployCrossChainNFT.s.sol";
import {CrossDomainEnabled} from "../lib/node_modules/@eth-optimism/contracts/libraries/bridge/CrossDomainEnabled.sol";
import {VRFCoordinatorV2Mock} from "../test/mocks/VRFCoordinatorV2Mock.sol";
import {LinkToken} from "../test/mocks/LinkToken.sol";
import {CrossDomainMessenger} from "../test/mocks/CrossDomainMessenger.sol";

contract HelperConfig is Script {
    NetworkConfig public activeNetworkConfig;

    // Struct that defines the network configuration.
    struct NetworkConfig {
        address op_CrossDomainMessengerAddr; //Address of the CrossDomainMessenger optimism Address
        address base_CrossDomainMessengerAddr; //Address of the CrossDomainMessenger base Address
        address zora_CrossDomainMessengerAddr; //Address of the CrossDomainMessenger zora Address
        address crossChainNFTL1Addr; // Address of the CrossChainNFT L1 Address
        uint64 subscriptionId; // Id of subscription to use
        bytes32 gasLane; // Address of the gas lane contract
        uint32 callbackGasLimit; // Gas limit for callbacks
        address vrfCoordinatorV2; // Address of the VRF coordinator
        address link; // Address of the LINK token contract
        uint256 deployerKey; // Private key of the deployer
    }

    uint256 public DEFAULT_ANVIL_PRIVATE_KEY =
        0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;

    // Event emitted when a mock VRF coordinator is created.
    event HelperConfig__CreatedMockVRFCoordinator(address vrfCoordinator);

    // Constructor that sets the active network configuration based on the chain id.
    constructor() {
        if (block.chainid == 5) {
            activeNetworkConfig = getGoerliEthConfig();
        } else {
            activeNetworkConfig = getOrCreateAnvilEthConfig();
        }
    }

    // Returns the network configuration for Goerli.
    function getGoerliEthConfig()
        public
        view
        returns (NetworkConfig memory goerliNetworkConfig)
    {
        goerliNetworkConfig = NetworkConfig({
            op_CrossDomainMessengerAddr: 0x5086d1eEF304eb5284A0f6720f79403b4e9bE294,
            base_CrossDomainMessengerAddr: 0x8e5693140eA606bcEB98761d9beB1BC87383706D,
            zora_CrossDomainMessengerAddr: 0xD87342e16352D33170557A7dA1e5fB966a60FafC,
            crossChainNFTL1Addr: vm.envAddress("GOERLI_CROSSCHAINNFT"),
            subscriptionId: 12614,
            gasLane: 0x79d3d8832d904592c0bf9818b621522c988bb8b0c05cdc3b15aea1b6e8db0c15,
            callbackGasLimit: 2500000, //
            vrfCoordinatorV2: 0x2Ca8E0C643bDe4C2E08ab1fA0da3401AdAD7734D,
            link: 0x326C977E6efc84E512bB9C30f76E30c160eD06FB,
            deployerKey: vm.envUint("PRIVATE_KEY")
        });
    }

    // Returns the network configuration for Anvil or creates it if it doesn't exist.
    function getOrCreateAnvilEthConfig()
        public
        returns (NetworkConfig memory anvilNetworkConfig)
    {
        // If an active network configuration for Anvil already exists, return it.
        if (activeNetworkConfig.vrfCoordinatorV2 != address(0)) {
            return activeNetworkConfig;
        }

        // Parameters for deploying VRFCoordinatorV2Mock
        uint96 baseFee = 0.25 ether;
        uint96 gasPriceLink = 1e9;

        // Start a broadcast transaction.
        vm.startBroadcast(DEFAULT_ANVIL_PRIVATE_KEY);
        // Deploy VRFCoordinatorV2Mock.
        VRFCoordinatorV2Mock vrfCoordinatorV2Mock = new VRFCoordinatorV2Mock(
            baseFee,
            gasPriceLink
        );

        LinkToken link = new LinkToken();
        vm.stopBroadcast();

        // Emitan event indicating that a mock VRF coordinator has been created.
        emit HelperConfig__CreatedMockVRFCoordinator(
            address(vrfCoordinatorV2Mock)
        );

        DeployCrossChainNFT deployer = new DeployCrossChainNFT();
        CrossChainNFT l1CrossChainNFT = deployer.run();
        address _crossChainNFTL1Addr = address(l1CrossChainNFT);

        // Set the network configuration for Anvil.
        anvilNetworkConfig = NetworkConfig({
            op_CrossDomainMessengerAddr: (address(new CrossDomainMessenger())),
            base_CrossDomainMessengerAddr: (
                address(new CrossDomainMessenger())
            ),
            zora_CrossDomainMessengerAddr: (
                address(new CrossDomainMessenger())
            ),
            crossChainNFTL1Addr: _crossChainNFTL1Addr,
            subscriptionId: 0, // If left as 0, our scripts will create one!
            gasLane: 0x79d3d8832d904592c0bf9818b621522c988bb8b0c05cdc3b15aea1b6e8db0c15,
            callbackGasLimit: 2500000, // 2500,000 gas
            vrfCoordinatorV2: address(vrfCoordinatorV2Mock),
            link: address(link),
            deployerKey: DEFAULT_ANVIL_PRIVATE_KEY
        });
    }
}
