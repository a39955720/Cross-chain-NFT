// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// Import CrossDomainMessenger contract
import {ICrossDomainMessenger} from "@eth-optimism/contracts/libraries/bridge/ICrossDomainMessenger.sol";

contract FromL2_ControlL1 {
    address private constant GOERLI_CROSSDOMAINMESSENGERADDR =
        0x4200000000000000000000000000000000000007;
    address private immutable i_l1Controller;

    // Constructor function to set the address of the L1 controller contract
    constructor(address l1Controller) {
        i_l1Controller = l1Controller;
    }

    // Function to initiate NFT minting on Layer 1 from Layer 2
    function mintNFT() public {
        bytes memory message = abi.encodeWithSignature(
            "mintNFT(address)",
            msg.sender
        );
        _sendMessage(message);
    }

    // Function to approve NFT transfer on Layer 1 from Layer 2
    function approve(address to, uint256 tokenId) public {
        bytes memory message = abi.encodeWithSignature(
            "approve(address,uint256)",
            to,
            tokenId
        );
        _sendMessage(message);
    }

    // Function to transfer NFT on Layer 1 from Layer 2
    function transferFrom(address from, address to, uint256 tokenId) public {
        bytes memory message = abi.encodeWithSignature(
            "transferFrom(address,address,uint256)",
            from,
            to,
            tokenId
        );
        _sendMessage(message);
    }

    // Function to safely transfer NFT on Layer 1 from Layer 2
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
    }

    // Function to safely transfer NFT with data on Layer 1 from Layer 2
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
    }

    // Function to set approval status for an operator on Layer 1 from Layer 2
    function setApprovalForAll(address operator, bool approved) public {
        bytes memory message = abi.encodeWithSignature(
            "setApprovalForAll(address,bool)",
            operator,
            approved
        );
        _sendMessage(message);
    }

    // Internal function to send messages to the L1 controller contract via CrossDomainMessenger
    function _sendMessage(bytes memory message) private {
        ICrossDomainMessenger(GOERLI_CROSSDOMAINMESSENGERADDR).sendMessage(
            i_l1Controller,
            message,
            1000000 // within the free gas limit amount
        );
    }
}
