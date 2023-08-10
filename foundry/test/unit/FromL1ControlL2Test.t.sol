// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {DeployFromL1ControlL2} from "../../script/DeployFromL1ControlL2.s.sol";
import {FromL1ControlL2} from "../../src/FromL1ControlL2.sol";
import {CrossChainNFT} from "../../src/CrossChainNFT.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {VRFCoordinatorV2Mock} from "../mocks/VRFCoordinatorV2Mock.sol";
import {Test, console} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";
import {StdCheats} from "forge-std/StdCheats.sol";

contract FromL1ControlL2Test is StdCheats, Test {
    FromL1ControlL2 fromL1ControlL2;
    HelperConfig helperConfig;
    address l1CrossChainNFT;
    address vrfCoordinatorV2;
    address OWNER = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    address MINTER = makeAddr("minter");
    address RECEIVER = makeAddr("receiver");

    event RequestedRandNum(uint256 indexed requestId);

    // Set up the initial configuration
    function setUp() external {
        DeployFromL1ControlL2 deployer = new DeployFromL1ControlL2();
        (fromL1ControlL2, helperConfig) = deployer.run();
        vm.prank(OWNER);
        (, , , l1CrossChainNFT, , , , vrfCoordinatorV2, , ) = helperConfig
            .activeNetworkConfig();
        vm.prank(OWNER);
        CrossChainNFT(l1CrossChainNFT).setFromL1ControlL2Addr(
            address(fromL1ControlL2)
        );
    }

    // Test the constructor functionality
    function testConstructor() public {
        assertEq(fromL1ControlL2.getCrossChainNFTL1Addr(), l1CrossChainNFT);
        assertEq(
            fromL1ControlL2.getCrossChainNFTL2Addr(0),
            vm.envAddress("OP_CROSSCHAINNFT")
        );
        assertEq(
            fromL1ControlL2.getCrossChainNFTL2Addr(1),
            vm.envAddress("BASE_CROSSCHAINNFT")
        );
        assertEq(
            fromL1ControlL2.getCrossChainNFTL2Addr(2),
            vm.envAddress("ZORA_CROSSCHAINNFT")
        );
        assertEq(fromL1ControlL2.getOwner(), OWNER);
        assertEq(uint256(fromL1ControlL2.getControllerState()), 0);
        assertEq(fromL1ControlL2.getTokenCounter(), 0);
    }

    // Test the setControllerStateToOpen function
    function testSetControllerStateToOpen() public {
        bytes memory customError = abi.encodeWithSignature(
            "FromL1ControlL2_NotOwner()"
        );
        vm.expectRevert(customError);
        fromL1ControlL2.setControllerStateToOpen();

        fromL1ControlL2.mintNFT();
        vm.prank(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
        fromL1ControlL2.setControllerStateToOpen();
        assertEq(uint256(fromL1ControlL2.getControllerState()), 0);
    }

    // Test the mintNFTFail function
    function testMintNFTFail() public {
        fromL1ControlL2.mintNFT();

        bytes memory customError = abi.encodeWithSignature(
            "FromL1ControlL2__ControllerStateNotOpen()"
        );
        vm.expectRevert(customError);
        fromL1ControlL2.mintNFT();
    }

    // Test the mintNFTSuccess function
    function testMintNFTSuccess() public {
        vm.recordLogs();
        fromL1ControlL2.mintNFT();

        Vm.Log[] memory entries = vm.getRecordedLogs();
        uint256 requestId = uint256(bytes32(entries[1].topics[1]));

        assert(requestId > 0);
        assertEq(uint256(fromL1ControlL2.getControllerState()), 1);
    }

    // Test the fulfillRandomWords function
    function testFulfillRandomWords() public {
        vm.recordLogs();
        vm.prank(MINTER);
        fromL1ControlL2.mintNFT();

        Vm.Log[] memory entries = vm.getRecordedLogs();
        uint256 requestId = uint256(bytes32(entries[1].topics[1]));
        VRFCoordinatorV2Mock(vrfCoordinatorV2).fulfillRandomWords(
            requestId,
            address(fromL1ControlL2)
        );

        assertEq(uint256(fromL1ControlL2.getControllerState()), 0);
        assertEq(fromL1ControlL2.getTokenCounter(), 1);
        assertEq(CrossChainNFT(l1CrossChainNFT).balanceOf(MINTER), 1);
        assertEq(CrossChainNFT(l1CrossChainNFT).ownerOf(0), MINTER);
    }

    // Modifier for mintNFT
    modifier mintNFT() {
        vm.recordLogs();
        vm.prank(MINTER);
        fromL1ControlL2.mintNFT();

        Vm.Log[] memory entries = vm.getRecordedLogs();
        uint256 requestId = uint256(bytes32(entries[1].topics[1]));
        VRFCoordinatorV2Mock(vrfCoordinatorV2).fulfillRandomWords(
            requestId,
            address(fromL1ControlL2)
        );
        _;
    }

    // Test the approve function
    function testApprove() public mintNFT {
        vm.prank(MINTER);
        fromL1ControlL2.approve(RECEIVER, 0);
        assertEq(CrossChainNFT(l1CrossChainNFT).getApproved(0), RECEIVER);
    }

    // Test the transferFrom function
    function testTransferFrom() public mintNFT {
        vm.prank(MINTER);
        fromL1ControlL2.approve(RECEIVER, 0);
        fromL1ControlL2.transferFrom(MINTER, RECEIVER, 0);
        assertEq(CrossChainNFT(l1CrossChainNFT).ownerOf(0), RECEIVER);
    }
}
