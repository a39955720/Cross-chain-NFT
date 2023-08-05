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

contract FromL1_ControlL2 is VRFConsumerBaseV2 {
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
    address private constant OP_CROSSDOMAINMESSENGERADDR =
        0x5086d1eEF304eb5284A0f6720f79403b4e9bE294;
    address private constant BASE_CROSSDOMAINMESSENGERADDR =
        0x8e5693140eA606bcEB98761d9beB1BC87383706D;
    address private constant ZORA_CROSSDOMAINMESSENGERADDR =
        0x9779A9D2f3B66A4F4d27cB99Ab6cC1266b3Ca9af;
    address private immutable i_crossChainNFTL1Addr;
    address[] internal i_crossChainNFTL2Addr;
    uint256 private immutable i_password;
    ControllerState private s_controllerState;
    uint256 private s_tokenCounter;
    address private s_msgSender;

    // Event fired when a random number is requested for NFT minting
    event RequestedRandNum(uint256 indexed requestId);

    constructor(
        address _crossChainNFTL1Addr,
        address[3] memory _crossChainNFTL2Addr,
        uint256 _password,
        address vrfCoordinatorV2,
        uint64 subscriptionId,
        bytes32 gasLane,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2(vrfCoordinatorV2) {
        i_crossChainNFTL1Addr = _crossChainNFTL1Addr;
        i_crossChainNFTL2Addr = _crossChainNFTL2Addr;
        i_password = _password;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        s_controllerState = ControllerState.OPEN;
        s_tokenCounter = 0;
    }

    // Modifier to restrict certain functions to when the controller state is OPEN
    modifier onlyOpen() {
        if (s_controllerState != ControllerState.OPEN) {
            revert FromL1ControlL2__ControllerStateNotOpen();
        }
        _;
    }

    // Modifier to restrict certain functions to be called only by the CrossDomainMessenger
    modifier onlyMessenger() {
        if (msg.sender != 0x4200000000000000000000000000000000000007) {
            revert FromL1ControlL2__YouCannotCallThisFunctionDirectly();
        }
        _;
    }

    //Only FromL2_ControlL1 can call this mintNFT function
    function mintNFT(address msgSender) public onlyOpen onlyMessenger {
        s_msgSender = msgSender;
        mintNFT();
    }

    //Everyone can call this mintNFT function
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

    // Callback function to receive random numbers from Chainlink VRF
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

    function approve(address to, uint256 tokenId) public {
        bytes memory message = abi.encodeWithSignature(
            "approve(address,uint256)",
            to,
            tokenId
        );
        _sendMessage(message);
        CrossChainNFT(i_crossChainNFTL1Addr).approve(to, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public {
        bytes memory message = abi.encodeWithSignature(
            "transferFrom(address,address,uint256)",
            from,
            to,
            tokenId
        );
        _sendMessage(message);
        CrossChainNFT(i_crossChainNFTL1Addr).transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public {
        bytes memory message = abi.encodeWithSignature(
            "safeTransferFrom(address,address,uint256)",
            from,
            to,
            tokenId
        );
        _sendMessage(message);
        CrossChainNFT(i_crossChainNFTL1Addr).safeTransferFrom(
            from,
            to,
            tokenId
        );
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public {
        bytes memory message = abi.encodeWithSignature(
            "safeTransferFrom(address,address,uint256,bytes)",
            from,
            to,
            tokenId,
            data
        );
        _sendMessage(message);
        CrossChainNFT(i_crossChainNFTL1Addr).safeTransferFrom(
            from,
            to,
            tokenId,
            data
        );
    }

    function setApprovalForAll(address operator, bool approved) public {
        bytes memory message = abi.encodeWithSignature(
            "setApprovalForAll(address,bool)",
            operator,
            approved
        );
        _sendMessage(message);
        CrossChainNFT(i_crossChainNFTL1Addr).setApprovalForAll(
            operator,
            approved
        );
    }

    // Internal function to send messages to the L2 contracts via CrossDomainMessenger
    function _sendMessage(bytes memory message) private {
        ICrossDomainMessenger(OP_CROSSDOMAINMESSENGERADDR).sendMessage(
            i_crossChainNFTL2Addr[0],
            message,
            1000000 // within the free gas limit amount
        );
        ICrossDomainMessenger(BASE_CROSSDOMAINMESSENGERADDR).sendMessage(
            i_crossChainNFTL2Addr[1],
            message,
            1000000
        );
        ICrossDomainMessenger(ZORA_CROSSDOMAINMESSENGERADDR).sendMessage(
            i_crossChainNFTL2Addr[2],
            message,
            1000000
        );
    }
}
