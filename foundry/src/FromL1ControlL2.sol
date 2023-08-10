// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// Import Chainlink VRF contract interfaces and CrossChainNFT contract
import {ICrossDomainMessenger} from "@eth-optimism/contracts/libraries/bridge/ICrossDomainMessenger.sol";
import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import {CrossChainNFT} from "./CrossChainNFT.sol";

// Error declarations
error FromL1ControlL2__ControllerStateNotOpen();
error FromL1ControlL2__YouCannotCallThisFunctionDirectly();
error FromL1ControlL2_NotOwner();

contract FromL1ControlL2 is VRFConsumerBaseV2 {
    // Enumeration representing the state of the controller
    enum ControllerState {
        OPEN,
        CALCULATING
    }

    // Chainlink VRF Variables
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    uint64 private immutable i_subscriptionId;
    bytes32 private immutable i_gasLane;
    uint32 private immutable i_callbackGasLimit;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;

    // Controller Variables
    address private immutable i_op_CrossDomainMessengerAddr;
    address private immutable i_base_CrossDomainMessengerAddr;
    address private immutable i_zora_CrossDomainMessengerAddr;
    address private immutable i_crossChainNFTL1Addr;
    address[] internal i_crossChainNFTL2Addr;
    uint256 private immutable i_password;
    address private immutable i_owner;
    ControllerState private s_controllerState;
    uint256 private s_tokenCounter;
    address private s_msgSender;

    // Event fired when a random number is requested for NFT minting
    event RequestedRandNum(uint256 indexed requestId);

    constructor(
        address op_CrossDomainMessengerAddr,
        address base_CrossDomainMessengerAddr,
        address zora_CrossDomainMessengerAddr,
        address crossChainNFTL1Addr,
        address op_CrossChainNFTL2Addr,
        address base_CrossChainNFTL2Addr,
        address zora_CrossChainNFTL2Addr,
        uint256 _password,
        address vrfCoordinatorV2,
        uint64 subscriptionId,
        bytes32 gasLane,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2(vrfCoordinatorV2) {
        i_op_CrossDomainMessengerAddr = op_CrossDomainMessengerAddr;
        i_base_CrossDomainMessengerAddr = base_CrossDomainMessengerAddr;
        i_zora_CrossDomainMessengerAddr = zora_CrossDomainMessengerAddr;
        i_crossChainNFTL1Addr = crossChainNFTL1Addr;
        i_crossChainNFTL2Addr = [
            op_CrossChainNFTL2Addr,
            base_CrossChainNFTL2Addr,
            zora_CrossChainNFTL2Addr
        ];
        i_password = _password;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        s_controllerState = ControllerState.OPEN;
        s_tokenCounter = 0;
        i_owner = msg.sender;
    }

    // Modifier to restrict certain functions to when the controller state is OPEN
    modifier onlyOpen() {
        if (s_controllerState != ControllerState.OPEN) {
            revert FromL1ControlL2__ControllerStateNotOpen();
        }
        _;
    }

    /**
     * @dev Public function to initiate the minting of a new NFT using Chainlink VRF
     */
    function mintNFT() public onlyOpen {
        s_controllerState = ControllerState.CALCULATING;
        s_msgSender = msg.sender;
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );
        emit RequestedRandNum(requestId);
    }

    /**
     * @dev Internal callback function to receive and process random numbers from Chainlink VRF
     *
     * @param randomWords (uint256[]) - array of random numbers received from Chainlink VRF
     */
    function fulfillRandomWords(
        uint256 /* requestId*/,
        uint256[] memory randomWords
    ) internal override {
        uint8 randNum = uint8(randomWords[0] % 100);
        bytes memory message = abi.encodeWithSignature(
            "mintNFT(address,uint256,uint8,uint256)",
            s_msgSender,
            s_tokenCounter,
            randNum,
            i_password
        );
        _sendMessage(message);
        CrossChainNFT(i_crossChainNFTL1Addr).mintNFT(
            s_msgSender,
            s_tokenCounter,
            randNum,
            i_password
        );
        s_controllerState = ControllerState.OPEN;
        s_tokenCounter++;
    }

    // Proxy functions for CrossChainNFT contract methods//

    /**
     * @dev Public function to approve the transfer of an NFT to an address for CrossChainNFT
     *
     * @param to (address) - address to which the NFT is approved to be transferred
     * @param tokenId (uint256) - token ID of the NFT to be approved for transfer
     */
    function approve(address to, uint256 tokenId) public {
        bytes memory message = abi.encodeWithSignature(
            "approveFromL1ControlL2(address,address,uint256,uint256)",
            msg.sender,
            to,
            tokenId,
            i_password
        );
        _sendMessage(message);
        CrossChainNFT(i_crossChainNFTL1Addr).approveFromL1ControlL2(
            msg.sender,
            to,
            tokenId,
            i_password
        );
    }

    /**
     * @dev Public function to transfer an NFT from one address to another for CrossChainNFT
     *
     * @param from (address) - address from which the NFT is transferred
     * @param to (address) - address to which the NFT is transferred
     * @param tokenId (uint256) - token ID of the NFT to be transferred
     */
    function transferFrom(address from, address to, uint256 tokenId) public {
        bytes memory message = abi.encodeWithSignature(
            "transferFromL1ControlL2(address,address,uint256,uint256)",
            from,
            to,
            tokenId,
            i_password
        );
        _sendMessage(message);
        CrossChainNFT(i_crossChainNFTL1Addr).transferFromL1ControlL2(
            from,
            to,
            tokenId,
            i_password
        );
    }

    /**
     * @dev Internal function to send messages to the L2 contracts via CrossDomainMessenger
     * @param message (bytes) - The message to be sent to the L2 contracts
     */
    function _sendMessage(bytes memory message) private {
        ICrossDomainMessenger(i_op_CrossDomainMessengerAddr).sendMessage(
            i_crossChainNFTL2Addr[0],
            message,
            200000 // within the free gas limit amount
        );
        ICrossDomainMessenger(i_base_CrossDomainMessengerAddr).sendMessage(
            i_crossChainNFTL2Addr[1],
            message,
            400000
        );
        ICrossDomainMessenger(i_zora_CrossDomainMessengerAddr).sendMessage(
            i_crossChainNFTL2Addr[2],
            message,
            400000
        );
    }

    /**
     * @dev Public function to set the controller state to OPEN
     * @notice Only the contract owner can call this function to allow minting
     */
    function setControllerStateToOpen() public {
        if (msg.sender != i_owner) {
            revert FromL1ControlL2_NotOwner();
        }
        s_controllerState = ControllerState.OPEN;
    }

    // Getter functions...
    function getControllerState() public view returns (ControllerState) {
        return s_controllerState;
    }

    function getCrossChainNFTL1Addr() public view returns (address) {
        return i_crossChainNFTL1Addr;
    }

    function getCrossChainNFTL2Addr(
        uint256 index
    ) public view returns (address) {
        return i_crossChainNFTL2Addr[index];
    }

    function getOwner() public view returns (address) {
        return i_owner;
    }

    function getTokenCounter() public view returns (uint256) {
        return s_tokenCounter;
    }
}
