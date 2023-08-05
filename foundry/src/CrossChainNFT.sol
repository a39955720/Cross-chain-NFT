// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// Import OpenZeppelin ERC721URIStorage extension for ERC721 tokens with URI storage
import {ERC721URIStorage, ERC721, IERC721} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

// Error declarations
error CrossChainNFT__AlreadyInitialized();
error CorssChainNFT__WrongPassword();
error CorssChainNFT__YouCannotCallThisFunctionDirectly();

contract CorssChainNFT is ERC721URIStorage {
    // Enumeration representing the types of NFTs
    enum NFT {
        GOLD,
        SILVER,
        BRONZE
    }

    uint256 private immutable i_password;
    bool private s_initialized;
    string[] internal s_CCNTokenUris;

    // Event fired when a new NFT is minted
    event NftMinted(NFT nft, address minter);

    constructor(
        string[3] memory CCNTokenUris,
        uint256 _password
    ) ERC721("Corss Chain NFT", "CCN") {
        i_password = _password; // Set the password
        _initializeContract(CCNTokenUris); // Initialize the contract with given token URIs
    }

    // Modifier to restrict certain functions to specific addresses
    modifier notMessenger() {
        if (
            msg.sender != 0x5086d1eEF304eb5284A0f6720f79403b4e9bE294 &&
            msg.sender != 0x8e5693140eA606bcEB98761d9beB1BC87383706D &&
            msg.sender != 0x363B4B1ADa52E50353f746999bd9E94395190d2C &&
            msg.sender != 0x4200000000000000000000000000000000000007
        ) {
            revert CorssChainNFT__YouCannotCallThisFunctionDirectly();
        }
        _;
    }

    // Modifier to check if the provided password is correct
    modifier wrongPassword(uint256 _password) {
        if (_password != i_password) {
            revert CorssChainNFT__WrongPassword();
        }
        _;
    }

    // Private function to initialize the contract with token URIs
    function _initializeContract(string[3] memory CCNTokenUris) private {
        // Check if the contract is already initialized
        if (s_initialized) {
            revert CrossChainNFT__AlreadyInitialized();
        }
        s_CCNTokenUris = CCNTokenUris; // Store the provided token URIs
        s_initialized = true; // Mark the contract as initialized
    }

    // Public function to mint a new NFT based on random number and token ID
    function mintNFT(
        address msgSender,
        uint256 tokenId,
        uint8 randNum,
        uint256 _password
    ) public notMessenger wrongPassword(_password) {
        NFT nft = getIndex(randNum);
        _safeMint(msgSender, tokenId);
        _setTokenURI(tokenId, s_CCNTokenUris[uint8(nft)]);
        emit NftMinted(nft, msgSender);
    }

    // Internal function to determine the NFT type based on the random number
    function getIndex(uint8 randNum) public pure returns (NFT) {
        if (randNum < 9) {
            return NFT(0);
        } else if (randNum < 39) {
            return NFT(1);
        } else {
            return NFT(2);
        }
    }

    ////////////////////////////////////////
    // override with notMessenger modifier//
    ////////////////////////////////////////

    function approve(
        address to,
        uint256 tokenId
    ) public override(ERC721, IERC721) notMessenger {
        super.approve(to, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721, IERC721) notMessenger {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721, IERC721) notMessenger {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override(ERC721, IERC721) notMessenger {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override(ERC721, IERC721) notMessenger {
        super.setApprovalForAll(operator, approved);
    }
}
