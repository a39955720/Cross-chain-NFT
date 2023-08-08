// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {DeployCrossChainNFT} from "../../script/DeployCrossChainNFT.s.sol";
import {CrossChainNFT} from "../../src/CrossChainNFT.sol";
import {Test, console} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";
import {StdCheats} from "forge-std/StdCheats.sol";

// Contract for testing the CrossChainNFT.sol
contract CrossChainNFTTest is StdCheats, Test {
    // Enumeration representing the types of NFTs
    enum NFT {
        GOLD,
        SILVER,
        BRONZE
    }

    // Declare public variables
    CrossChainNFT public crossChainNFT;
    address public fromL1ControlL2Addr =
        0x0000000000000000000000000000000000000000;
    address public MINTER = makeAddr("minter");

    // Declare an event for logging NFT minting
    event NftMinted(NFT nft, address minter);

    // Set up function to be executed before each test
    function setUp() external {
        // Create a new instance of the DeployCrossChainNFT contract
        DeployCrossChainNFT deployer = new DeployCrossChainNFT();
        // Deploy the CrossChainNFT contract and assign it to the public variable
        crossChainNFT = deployer.run();
    }

    // Test function to check the constructor of the CrossChainNFT contract
    function testConstructor() public {
        // Check CCN token URIs and owner
        assertEq(
            crossChainNFT.getTokenUris(0),
            "ipfs://QmYZ8GkP5NamhgmdZHomfiFQqizG2cY3UWBNV5RNKuapuy"
        );
        assertEq(
            crossChainNFT.getTokenUris(1),
            "ipfs://QmXs5UeXttXRAe6eMM6h7mwGL2mxDcUqgXcqacH79JMPPK"
        );
        assertEq(
            crossChainNFT.getTokenUris(2),
            "ipfs://QmSqjLJSfLjuDd8ENYigTNtrcb89Modm95kR4w8jb57dqP"
        );
        assertEq(
            crossChainNFT.getOwner(),
            0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
        );
    }

    // Test function to check setting FromL1ControlL2 address
    function testFromL1ControlL2Addr() public {
        // Define an error message that represents the custom error "CrossChainNFT__NotOwner()"
        bytes memory customError = abi.encodeWithSignature(
            "CrossChainNFT__NotOwner()"
        );

        // Expect a revert with the defined custom error message
        vm.expectRevert(customError);
        crossChainNFT.setFromL1ControlL2Addr(fromL1ControlL2Addr);

        // Define another custom error message "CrossChainNFT__AlreadyInitialized()"
        customError = abi.encodeWithSignature(
            "CrossChainNFT__AlreadyInitialized()"
        );
        // Prank the sender to simulate a owner address
        vm.prank(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
        crossChainNFT.setFromL1ControlL2Addr(fromL1ControlL2Addr);

        // Expect a revert with the "CrossChainNFT__AlreadyInitialized()" error
        vm.expectRevert(customError);
        vm.prank(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
        crossChainNFT.setFromL1ControlL2Addr(fromL1ControlL2Addr);

        // Assert that the contract has been initialized and the FromL1ControlL2 address is set
        assertEq(crossChainNFT.getInitialized(), true);
        assertEq(crossChainNFT.getFromL1ControlL2Addr(), fromL1ControlL2Addr);
    }

    // Test function to simulate a failure scenario when minting NFTs
    function testMintNFTFail() public {
        // Define an error message that represents the custom error "CrossChainNFT__YouCannotCallThisFunctionDirectly()"
        bytes memory customError = abi.encodeWithSignature(
            "CorssChainNFT__YouCannotCallThisFunctionDirectly()"
        );

        // Expect a revert with the defined custom error message
        vm.expectRevert(customError);
        crossChainNFT.mintNFT(MINTER, 0, 0, vm.envUint("PASSWORD"));

        // Define another custom error message "CrossChainNFT__WrongPassword()"
        customError = abi.encodeWithSignature("CorssChainNFT__WrongPassword()");
        // Prank the sender to simulate Messenger sender address
        vm.prank(0x4200000000000000000000000000000000000007);
        // Expect a revert with the "CrossChainNFT__WrongPassword()" error
        vm.expectRevert(customError);
        // Try to mint an NFT with an incorrect password
        crossChainNFT.mintNFT(MINTER, 0, 0, 123);
    }

    // Test function to simulate a successful scenario when minting NFTs
    function testMintNFTSuccess() public {
        vm.prank(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
        crossChainNFT.setFromL1ControlL2Addr(fromL1ControlL2Addr);

        vm.prank(fromL1ControlL2Addr);
        vm.expectEmit(true, true, false, true, address(crossChainNFT));
        emit NftMinted(NFT(0), MINTER);
        crossChainNFT.mintNFT(MINTER, 0, 0, vm.envUint("PASSWORD"));

        vm.prank(fromL1ControlL2Addr);
        vm.expectEmit(true, true, false, true, address(crossChainNFT));
        emit NftMinted(NFT(1), MINTER);
        crossChainNFT.mintNFT(MINTER, 1, 10, vm.envUint("PASSWORD"));

        vm.prank(fromL1ControlL2Addr);
        vm.expectEmit(true, true, false, true, address(crossChainNFT));
        emit NftMinted(NFT(2), MINTER);
        crossChainNFT.mintNFT(MINTER, 2, 40, vm.envUint("PASSWORD"));

        // Assert that the balance and ownership of NFTs are correct
        assertEq(crossChainNFT.balanceOf(MINTER), 3);
        assertEq(crossChainNFT.ownerOf(2), MINTER);
    }

    // Modifier for minting an NFT before executing a test function
    modifier mintNFT() {
        vm.prank(fromL1ControlL2Addr);
        crossChainNFT.mintNFT(MINTER, 0, 0, vm.envUint("PASSWORD"));
        _;
    }

    // Test function to simulate a failure scenario when approving NFT transfer
    function testApproveFail(address to) public mintNFT {
        bytes memory customError = abi.encodeWithSignature(
            "CorssChainNFT__YouCannotCallThisFunctionDirectly()"
        );
        vm.expectRevert(customError);
        crossChainNFT.approve(to, 0);
    }

    // ... (similar test functions for other NFT transfer scenarios)//

    function testTransferFromFail(address to) public mintNFT {
        bytes memory customError = abi.encodeWithSignature(
            "CorssChainNFT__YouCannotCallThisFunctionDirectly()"
        );
        vm.expectRevert(customError);
        crossChainNFT.transferFrom(MINTER, to, 0);
    }

    function testSafeTransferFromFail(address to) public mintNFT {
        bytes memory customError = abi.encodeWithSignature(
            "CorssChainNFT__YouCannotCallThisFunctionDirectly()"
        );
        vm.expectRevert(customError);
        crossChainNFT.safeTransferFrom(MINTER, to, 0);
    }

    function testSafeTransferFromFail(
        address to,
        bytes memory data
    ) public mintNFT {
        bytes memory customError = abi.encodeWithSignature(
            "CorssChainNFT__YouCannotCallThisFunctionDirectly()"
        );
        vm.expectRevert(customError);
        crossChainNFT.safeTransferFrom(MINTER, to, 0, data);
    }

    function testSetApprovalForAllFail(
        address operator,
        bool approved
    ) public mintNFT {
        bytes memory customError = abi.encodeWithSignature(
            "CorssChainNFT__YouCannotCallThisFunctionDirectly()"
        );
        vm.expectRevert(customError);
        crossChainNFT.setApprovalForAll(operator, approved);
    }
}
