// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {DeployOurToken} from "../script/DeployOurToken.s.sol";
import {OurToken} from "../src/OurToken.sol";
import {Test, console} from "forge-std/Test.sol";
import {StdCheats} from "forge-std/StdCheats.sol";

interface MintableToken {
    function mint(address, uint256) external;
}

contract OurTokenTest is StdCheats, Test {
    OurToken public ourToken;
    DeployOurToken public deployer;
    address public deployerAddress;
    address public user1;
    address public user2;

    function setUp() public {
        deployer = new DeployOurToken();
        ourToken = deployer.run();
        // deployerAddress = vm.addr(deployer.deployerPrivateKey());

        // deployerAddress = deployer.deployer(); // Access the deployer's address

        // Create two user accounts for testing
        user1 = vm.addr(1);
        user2 = vm.addr(2);

        // Distribute some tokens to user1 for testing
        vm.prank(msg.sender);
        ourToken.transfer(user1, 1000 ether);
    }

    function testInitialSupply() public {
        assertEq(ourToken.totalSupply(), deployer.INITIAL_SUPPLY());
    }

    function testUsersCantMint() public {
        vm.expectRevert();
        MintableToken(address(ourToken)).mint(address(this), 1);
    }

    function testAllowance() public {
        uint256 initialAllowance = 500 ether;

        // Approve user2 to spend tokens on behalf of user1
        vm.prank(user1);
        ourToken.approve(user2, initialAllowance);

        // Check the allowance
        assertEq(ourToken.allowance(user1, user2), initialAllowance);

        // Increase the allowance by re-approving with a higher value
        uint256 additionalAllowance = initialAllowance + 300 ether;
        vm.prank(user1);
        ourToken.approve(user2, additionalAllowance);
        assertEq(ourToken.allowance(user1, user2), additionalAllowance);

        // Decrease the allowance by re-approving with a lower value
        uint256 decreasedAllowance = additionalAllowance - 200 ether;
        vm.prank(user1);
        ourToken.approve(user2, decreasedAllowance);
        assertEq(ourToken.allowance(user1, user2), decreasedAllowance);
    }

    function testTransfer() public {
        uint256 transferAmount = 100 ether;
        uint256 initialBalance = ourToken.balanceOf(user2);

        // Transfer tokens from user1 to user2
        vm.prank(user1);
        ourToken.transfer(user2, transferAmount);

        // Check balances
        assertEq(ourToken.balanceOf(user1), 900 ether);
        assertEq(ourToken.balanceOf(user2), initialBalance + transferAmount);
    }

    function testTransferFrom() public {
        uint256 transferAmount = 200 ether;
        uint256 initialBalanceUser2 = ourToken.balanceOf(user2);

        // Approve user2 to spend tokens on behalf of user1
        vm.prank(user1);
        ourToken.approve(user2, transferAmount);

        // Transfer tokens from user1 to user2 via user2
        vm.prank(user2);
        ourToken.transferFrom(user1, user2, transferAmount);

        // Check balances
        assertEq(ourToken.balanceOf(user1), 800 ether);
        assertEq(
            ourToken.balanceOf(user2),
            initialBalanceUser2 + transferAmount
        );
    }

    function testTransferExceedsBalance() public {
        uint256 transferAmount = 1100 ether;

        // Attempt to transfer more than balance
        vm.prank(user1);
        vm.expectRevert();
        ourToken.transfer(user2, transferAmount);
    }

    function testTransferFromExceedsAllowance() public {
        uint256 transferAmount = 300 ether;
        uint256 approvedAmount = 100 ether;

        // Approve user2 to spend a smaller amount of tokens on behalf of user1
        vm.prank(user1);
        ourToken.approve(user2, approvedAmount);

        // Attempt to transfer more than allowed
        vm.prank(user2);
        vm.expectRevert();
        ourToken.transferFrom(user1, user2, transferAmount);
    }

    function testBurn() public {
        uint256 burnAmount = 200 ether;
        uint256 initialSupply = ourToken.totalSupply();
        uint256 initialBalance = ourToken.balanceOf(user1);

        // Burn tokens from user1
        vm.prank(user1);
        ourToken.burn(burnAmount);

        // Check balance and total supply
        assertEq(ourToken.balanceOf(user1), initialBalance - burnAmount);
        assertEq(ourToken.totalSupply(), initialSupply - burnAmount);
    }
}
