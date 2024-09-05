// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {MockV3Aggregator} from "../test/mocks/MockV3Aggregator.sol";

contract HelperConfig is Script {
    // if we are in a test environment, we want to use the mock price feed
    // if we are in a real environment, we want to use the real price feed
    // if we are in a local environment, we want to use the local price feed

    uint8 public constant DECIMALS = 8;
    int256 public constant INITIAL_PRICE = 2000000000000000000000000;

    NetworkConfig public activeNetworkConfig;

    struct NetworkConfig {
        address priceFeed;
    }

    constructor() {
        if (block.chainid == 11155111) {
            activeNetworkConfig = getSepoliaEthConfig();
        } else if (block.chainid == 1) {
            activeNetworkConfig = getMainnetEthConfig();
        } else {
            activeNetworkConfig = getOrCreateAnvilEthConfig();
        }
    }

    function getSepoliaEthConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory SepoliaConfig = NetworkConfig({
            priceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306
        });
        return SepoliaConfig;
    }

    function getMainnetEthConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory MainnetConfig = NetworkConfig({
            priceFeed: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
        });
        return MainnetConfig;
    }

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        // checks if there is already a mock deployed or whether there is already an address in the activeNetworkConfig
        // address(0) is the default value for an address
        if (activeNetworkConfig.priceFeed != address(0)) {
            return activeNetworkConfig;
        }

        // 1. Deploy mocks
        // 2. Return the mock address
        vm.startBroadcast();
        MockV3Aggregator mockV3Aggregator = new MockV3Aggregator(
            DECIMALS,
            INITIAL_PRICE
        );
        vm.stopBroadcast();

        NetworkConfig memory AnvilConfig = NetworkConfig({
            priceFeed: address(mockV3Aggregator)
        });
        return AnvilConfig;
    }
}
