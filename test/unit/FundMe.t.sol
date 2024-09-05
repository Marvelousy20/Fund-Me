// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;
    address USER = makeAddr("user");
    uint256 constant SEND_VALUE = 0.1 ether; // 0.1 ETH = 100000000000000000
    uint256 constant GAS_PRICE = 1;
    uint256 constant STARTING_BALANCE = 10 ether;

    function setUp() external {
        // fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, STARTING_BALANCE);
    }

    function testMinDollarIsFive() public view {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsMsgSender() public view {
        // address(this) is the address of the contract
        // msg.sender is the address of the person who is calling the function
        // assertEq(fundMe.i_owner(), address(this)); This was changed because
        // the contract deploying the fundMe is now the DeployfundMe script

        assertEq(fundMe.getOwner(), msg.sender);
    }

    function testConversionVersion() public view {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }

    function testFundsWithoutEnoughtEth() public {
        //  line vm.expectRevert() is a test for a revert and it means the test should fail if the revert does not happen
        vm.expectRevert();
        fundMe.fund();
    }

    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    function testDataStructuresUpdated() public {
        // vm.prank is used to change the address of the msg.sender
        // It means that the function will be called by the address of USER
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();

        uint256 amountFunded = fundMe.getAddressToAmmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }

    function testAddsFunderToArrayOfFunders() public {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        address firstFunder = fundMe.getFunders(0);
        assertEq(firstFunder, USER);
    }

    function testOnlyOwnerCanWithdraw() public funded {
        // fund the contract with the user address, modifier funded is used to fund the contract
        // vm.prank(USER);
        // fundMe.fund{value: SEND_VALUE}();

        vm.expectRevert(); // expect the next transaction to revert
        vm.prank(USER);
        fundMe.withdraw();
    }

    function testWithdrawWithASingleFunder() public funded {
        // Arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingContractBalance = address(fundMe).balance;

        // act
        // Act like the owner and call the withdraw function
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        // Assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingContractBalance = address(fundMe).balance;
        assertEq(
            startingOwnerBalance + startingContractBalance,
            endingOwnerBalance
        );
        assertEq(endingContractBalance, 0);
    }

    function testWithDrawFromMultipleFunders() public funded {
        // Arrange
        // We usee the numberOfFunders to create a loop that will create a number of funders (addresses)
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;
        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            // hoax is a function that is used to create a new address and fund it with a certain amount of ETH
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingContractBalance = address(fundMe).balance;

        // Act
        // vm.txGasPrice(GAS_PRICE); // This is used to set the gas price for the transaction
        // The goal is to get the gas used to execute the transaction
        // uint256 gasStart = gasleft();
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();
        // uint256 gasEnd = gasleft();

        // uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice; // ts.gasprice is 1
        // console.log(gasUsed);
        // Assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingContractBalance = address(fundMe).balance;
        assertEq(endingContractBalance, 0);
        assertEq(
            startingContractBalance + startingOwnerBalance,
            endingOwnerBalance
        );
    }

    function testWithDrawFromMultipleFundersCheaper() public funded {
        // Arrange
        // We use the numberOfFunders to create a loop that will create a number of funders (addresses)
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;
        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            // hoax is a function that is used to create a new address and fund it with a certain amount of ETH
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingContractBalance = address(fundMe).balance;

        // Act
        // vm.txGasPrice(GAS_PRICE); // This is used to set the gas price for the transaction
        // The goal is to get the gas used to execute the transaction
        // uint256 gasStart = gasleft();
        vm.startPrank(fundMe.getOwner());
        fundMe.cheaperWithdraw();
        vm.stopPrank();
        // uint256 gasEnd = gasleft();

        // uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice; // ts.gasprice is 1
        // console.log(gasUsed);
        // Assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingContractBalance = address(fundMe).balance;
        assertEq(endingContractBalance, 0);
        assertEq(
            startingContractBalance + startingOwnerBalance,
            endingOwnerBalance
        );
    }
}
