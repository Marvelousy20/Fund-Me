// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

import {PriceConverter} from "./PriceConverter.sol";

error FundMe__NotOwner();
error FundMe__CallFailed();
error FundMe__NotEnoughETHSent();

contract FundMe {
    using PriceConverter for uint256;

    // s_ stands for storage
    // i_ stands for immutable

    mapping(address => uint256) private s_addressToAmountFunded;

    // Could we make this constant?  /* hint: no! We should make it immutable! */
    address private immutable i_owner;

    uint256 public constant MINIMUM_USD = 5 * 10 ** 18;

    // s_priceFeed is a storage variable and what it is is an instance of the AggregatorV3Interface that we imported
    // it is used to get the price of the ETH/USD
    AggregatorV3Interface private s_priceFeed;
    address[] private s_funders;

    constructor(address priceFeed) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeed);
    }

    function fund() public payable {
        // require(
        //     msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD,
        //     "You need to spend more ETH!"
        // );

        if (msg.value.getConversionRate(s_priceFeed) < MINIMUM_USD)
            revert FundMe__NotEnoughETHSent();

        // require(PriceConverter.getConversionRate(msg.value) >= MINIMUM_USD, "You need to spend more ETH!");
        s_addressToAmountFunded[msg.sender] += msg.value;
        s_funders.push(msg.sender);
    }

    function getVersion() public view returns (uint256) {
        // AggregatorV3Interface priceFeed = AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        return s_priceFeed.version();
    }

    modifier onlyOwner() {
        // require(msg.sender == owner);
        if (msg.sender != i_owner) revert FundMe__NotOwner();
        _;
    }

    function cheaperWithdraw() public onlyOwner {
        uint256 fundersLength = s_funders.length;
        for (uint256 i = 0; i < fundersLength; i++) {
            address s_funder = s_funders[i];
            s_addressToAmountFunded[s_funder] = 0;
        }
        // reset the array
        s_funders = new address[](0);

        // call
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        if (!callSuccess) revert FundMe__CallFailed();
    }

    function withdraw() public onlyOwner {
        for (
            uint256 funderIndex = 0;
            // the length of the array is stored in storage. Iterating over the array (storage) is expensive.
            funderIndex < s_funders.length;
            funderIndex++
        ) {
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);
        // // transfer
        // payable(msg.sender).transfer(address(this).balance);

        // // send
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess, "Send failed");

        // call
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        if (!callSuccess) revert FundMe__CallFailed();
    }
    // Explainer from: https://solidity-by-example.org/fallback/
    // Ether is sent to contract
    //      is msg.data empty?
    //          /   \
    //         yes  no
    //         /     \
    //    receive()?  fallback()
    //     /   \
    //   yes   no
    //  /        \
    //receive()  fallback()

    fallback() external payable {
        fund();
    }

    receive() external payable {
        fund();
    }

    // Getter functions: This is where the private variables are exposed to the public

    // Get amount funded by address
    function getAddressToAmmountFunded(
        address fundingAddress
    ) public view returns (uint256) {
        return s_addressToAmountFunded[fundingAddress];
    }

    // Get funders
    function getFunders(uint256 index) public view returns (address) {
        return s_funders[index];
    }

    function getOwner() external view returns (address) {
        return i_owner;
    }
}

// Concepts we didn't cover yet (will cover in later sections)
// 1. Enum
// 2. Events
// 3. Try / Catch
// 4. Function Selector
// 5. abi.encode / decode
// 6. Hash with keccak256
// 7. Yul / Assembly
