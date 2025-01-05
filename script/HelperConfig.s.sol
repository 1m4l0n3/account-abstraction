//SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "../lib/forge-std/src/Script.sol";
import {EntryPoint} from "../lib/account-abstraction/contracts/core/EntryPoint.sol";

contract HelperConfig is Script {
    error HelperConfig__InvalidChainId();

    struct NetworkConfig {
        address entryPoint;
        address account;
    }

    uint256 constant ETH_SEPOLIA_CHAIN_ID = 11155111;
    uint256 constant ZKSYNC_SEPOLIA_CHAIN_ID = 300;
    uint256 constant LOCAL_CHAIN_ID = 31337;
    address private anvilAccountAddress = vm.parseAddress(vm.envString("ANVIL_DEFAULT_ACCOUNT"));
    address private burnerAccountAddress = vm.parseAddress(vm.envString("BURNER_ACCOUNT"));
    NetworkConfig public networkConfig;
    mapping(uint256 chainId => NetworkConfig networkConfig) public networkConfigs;

    constructor() {
        networkConfigs[ETH_SEPOLIA_CHAIN_ID] = getEthSepoliaConfig();
        networkConfigs[ZKSYNC_SEPOLIA_CHAIN_ID] = getZkSyncSepoliaConfig();
    }

    function getConfig() public returns(NetworkConfig memory) {
        return getConfigByChainId(block.chainid);
    }

    function getConfigByChainId(uint256 chainId) public returns(NetworkConfig memory) {
        if (chainId == LOCAL_CHAIN_ID) {
            return getOrCreateAnvilEthConfig();
        }
        else if (networkConfigs[chainId].account != address(0)) {
            return networkConfigs[chainId];
        }
        revert HelperConfig__InvalidChainId();
    }

    function getEthSepoliaConfig() public view returns(NetworkConfig memory) {
        return NetworkConfig({
            entryPoint: 0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789,
            account: burnerAccountAddress
        });
    }

    function getZkSyncSepoliaConfig() public view returns(NetworkConfig memory) {
        return NetworkConfig({
            entryPoint: address(0),
            account: burnerAccountAddress
        });
    }

    function getOrCreateAnvilEthConfig() public returns(NetworkConfig memory)  {
        if (networkConfigs[LOCAL_CHAIN_ID].account != address(0)){
            return networkConfigs[LOCAL_CHAIN_ID];
        }

        vm.startBroadcast(anvilAccountAddress);
        EntryPoint entryPoint = new EntryPoint();
        vm.stopBroadcast();

        networkConfigs[LOCAL_CHAIN_ID] = NetworkConfig({
            entryPoint : address(entryPoint),
            account : anvilAccountAddress
        });

        return networkConfigs[LOCAL_CHAIN_ID];
    }
}