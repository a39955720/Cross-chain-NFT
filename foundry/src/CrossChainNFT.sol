// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// Import OpenZeppelin ERC721URIStorage extension for ERC721 tokens with URI storage
import {ERC721URIStorage} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

// Error declarations
error CrossChainNFT__AlreadyInitialized();
error CorssChainNFT__WrongPassword();
error CorssChainNFT__YouCannotCallThisFunctionDirectly();
error CrossChainNFT_NotOwner();

contract CrossChainNFT is ERC721URIStorage {
    // Enumeration representing the types of NFTs
    enum NFT {
        GOLD,
        SILVER,
        BRONZE
    }

    uint256 private immutable i_password;
    bool private s_initialized;
    string[] internal s_CCNTokenUris;
    address private i_owner;
    address private i_fromL1ControlL2Addr;

    // Event fired when a new NFT is minted
    event NftMinted(NFT nft, address minter);

    constructor(
        string[3] memory ccnTokenUris,
        uint256 _password
    ) ERC721("Corss Chain NFT", "CCN") {
        i_password = _password; // Set the password
        _initializeContract(ccnTokenUris); // Initialize the contract with given token URIs
        i_owner = msg.sender;
    }

    // Modifier to restrict certain functions to specific addresses
    modifier onlyMessenger() {
        if (
            msg.sender != i_fromL1ControlL2Addr &&
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

    function setFromL1ControlL2Addr(address fromL1ControlL2Addr) public {
        if (msg.sender != i_owner) {
            revert CrossChainNFT_NotOwner();
        }
        i_fromL1ControlL2Addr = fromL1ControlL2Addr;
    }

    // Public function to mint a new NFT based on random number and token ID
    function mintNFT(
        address msgSender,
        uint256 tokenId,
        uint8 randNum,
        uint256 _password
    ) public onlyMessenger wrongPassword(_password) {
        NFT nft = getIndex(randNum);
        _safeMint(msgSender, tokenId);
        _setTokenURI(tokenId, s_CCNTokenUris[uint8(nft)]);
        emit NftMinted(nft, msgSender);
    }

    // Internal function to determine the NFT type based on the random number
    function getIndex(uint8 randNum) public pure returns (NFT) {
        if (randNum < 9) {
            return NFT.GOLD;
        } else if (randNum < 39) {
            return NFT.SILVER;
        } else {
            return NFT.BRONZE;
        }
    }

    ////////////////////////////////////////
    // override with notMessenger modifier//
    ////////////////////////////////////////

    function approve(
        address to,
        uint256 tokenId
    ) public override onlyMessenger {
        super.approve(to, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyMessenger {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyMessenger {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override onlyMessenger {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override onlyMessenger {
        super.setApprovalForAll(operator, approved);
    }
}
