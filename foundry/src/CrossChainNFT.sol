// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// Import OpenZeppelin ERC721URIStorage extension for ERC721 tokens with URI storage
import {ERC721URIStorage, ERC721} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

// Error declarations
error CrossChainNFT__AlreadyInitialized();
error CorssChainNFT__WrongPassword();
error CorssChainNFT__YouCannotCallThisFunctionDirectly();
error CrossChainNFT__NotOwner();

contract CrossChainNFT is ERC721URIStorage {
    // Enumeration representing the types of NFTs
    enum NFT {
        GOLD,
        SILVER,
        BRONZE
    }

    uint256 private immutable i_password;
    bool private s_initialized;
    string[] internal s_ccnTokenUris;
    address private immutable i_owner;
    address private s_fromL1ControlL2Addr;

    // Event fired when a new NFT is minted
    event NftMinted(NFT nft, address minter);

    /**
     * @dev Constructor to initialize the CrossChainNFT contract
     * @param ccnTokenUris (string[3] memory) - URIs of the NFT tokens
     * @param _password (uint256) - password for function validation
     */
    constructor(
        string[3] memory ccnTokenUris,
        uint256 _password
    ) ERC721("Corss Chain NFT", "CCN") {
        i_password = _password; // Set the password
        s_ccnTokenUris = ccnTokenUris; // Initialize the contract with given token URIs
        i_owner = msg.sender;
    }

    // Modifier to restrict certain functions to specific addresses
    modifier onlyMessenger() {
        if (
            msg.sender != s_fromL1ControlL2Addr &&
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

    /**
     * @dev Function to set the address of the L1 to L2 bridge contract
     * @param fromL1ControlL2Addr (address) - address of the L1 to L2 bridge contract
     */
    function setFromL1ControlL2Addr(address fromL1ControlL2Addr) public {
        if (msg.sender != i_owner) {
            revert CrossChainNFT__NotOwner();
        }
        if (s_initialized) {
            revert CrossChainNFT__AlreadyInitialized();
        }
        s_fromL1ControlL2Addr = fromL1ControlL2Addr;
        s_initialized = true;
    }

    /**
     * @dev Public function to mint a new NFT based on a random number and token ID
     *
     * @param msgSender (address) - address of the Minter
     * @param tokenId (uint256) - token ID of the newly minted NFT
     * @param randNum (uint8) - random number used to determine the NFT type
     * @param _password (uint256) - password provided to verify access
     */
    function mintNFT(
        address msgSender,
        uint256 tokenId,
        uint8 randNum,
        uint256 _password
    ) public onlyMessenger wrongPassword(_password) {
        NFT nft = getIndex(randNum);
        _safeMint(msgSender, tokenId);
        _setTokenURI(tokenId, s_ccnTokenUris[uint8(nft)]);
        emit NftMinted(nft, msgSender);
    }

    /**
     * @dev Internal function to determine the NFT type based on the random number
     *
     * @param randNum (uint8) - random number used to determine NFT type
     * @return NFT - type of NFT based on the random number
     */
    function getIndex(uint8 randNum) internal pure returns (NFT) {
        if (randNum < 9) {
            return NFT.GOLD;
        } else if (randNum < 39) {
            return NFT.SILVER;
        } else {
            return NFT.BRONZE;
        }
    }

    /**
     * @dev Public function to approve the transfer of an NFT from L1 ControlL2
     *
     * @param msgSender (address) - address of the message sender
     * @param to (address) - address to which the NFT is approved to be transferred
     * @param tokenId (uint256) - token ID of the NFT to be approved for transfer
     * @param password (uint256) - password provided to verify access
     */
    function approveFromL1ControlL2(
        address msgSender,
        address to,
        uint256 tokenId,
        uint256 password
    ) public onlyMessenger wrongPassword(password) {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            msgSender == owner || isApprovedForAll(owner, msgSender),
            "ERC721: approve caller is not token owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev Public function to transfer an NFT from L1 ControlL2
     *
     * @param msgSender (address) - address of the message sender
     * @param to (address) - address to which the NFT is transferred
     * @param tokenId (uint256) - token ID of the NFT to be transferred
     * @param password (uint256) - password provided to verify access
     */
    function transferFromL1ControlL2(
        address msgSender,
        address to,
        uint256 tokenId,
        uint256 password
    ) public onlyMessenger wrongPassword(password) {
        _safeTransfer(msgSender, to, tokenId, "");
    }

    ////////////////////////////////////////
    // override with notMessenger modifier//
    ////////////////////////////////////////

    function approve(
        address to,
        uint256 tokenId
    ) public override onlyMessenger {}

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyMessenger {}

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyMessenger {}

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override onlyMessenger {}

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override onlyMessenger {}

    // Getter functions...
    function getTokenUris(uint256 index) public view returns (string memory) {
        return s_ccnTokenUris[index];
    }

    function getOwner() public view returns (address) {
        return i_owner;
    }

    function getInitialized() public view returns (bool) {
        return s_initialized;
    }

    function getFromL1ControlL2Addr() public view returns (address) {
        return s_fromL1ControlL2Addr;
    }
}
