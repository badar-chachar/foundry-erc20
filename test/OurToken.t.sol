// SPDX-License-Identifier: SEE LICENSE IN LICENSE

pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {OurToken} from "../src/OurToken.sol";
import {DeployOurToken} from "../script/DeployOurToken.s.sol";

contract TestOurToken is Test {
    OurToken public ourToken;
    DeployOurToken public deployer;

    address bob = makeAddr("Bob");
    address alice = makeAddr("Alice");

    uint256 public constant STARTING_BALANCE = 10 ether;

    function setUp() public {
        deployer = new DeployOurToken();
        ourToken = deployer.run();

        vm.prank(msg.sender);
        ourToken.transfer(bob, STARTING_BALANCE);
    }

    function testBobHasStartingBalance() public view {
        assertEq(ourToken.balanceOf(bob), STARTING_BALANCE);
    }

    function testAllowancesWorks() public {
        uint256 initialAllowances = 100;
        uint256 transferAmount = 50;
        // Bob approve Allice to spend on his behalf

        vm.prank(bob);
        ourToken.approve(alice, initialAllowances);

        vm.prank(alice);
        ourToken.transferFrom(bob, alice, transferAmount);

        assertEq(ourToken.balanceOf(alice), transferAmount);
        assertEq(ourToken.balanceOf(bob), STARTING_BALANCE - transferAmount);
        assertEq(
            ourToken.allowance(bob, alice),
            initialAllowances - transferAmount
        );
        // console.log(ourToken.allowance(bob, alice));
    }
}
