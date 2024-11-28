// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import {Script} from "forge-std/Script.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

abstract contract CodeConstants {
    //VRF Mock Values
    uint96 public MOCK_BASE_FEE = 0.25 ether;
    uint96 public MOCK_GAS_PRICE_LINK = 1e9;
    //LINK / ETH price
    int256 public MOCK_WEI_PER_UINT_LINK = 4e15;

    uint256 public constant EHT_SEPOLIA_CHAIN_ID = 11155111;
    uint256 public constant LOCAL_CHAIN_ID = 31337;
}

contract HelperConfig is CodeConstants, Script {
    error HelperConfig__InvalidChainId();

    struct NetworkConfig {
        uint256 entryFee;
        uint256 interval;
        address vrfCoordinator;
        bytes32 gasLane;
        uint256 subscriptionId;
        uint32 callbackGasLimit;
    }
    NetworkConfig public LocalNetworkConfig;
    mapping(uint256 chainId => NetworkConfig) public networkConfig;

    constructor() {
        networkConfig[EHT_SEPOLIA_CHAIN_ID] = getSepoliaConfig();
    }

    function getConfigByChainId(
        uint256 chainId
    ) public returns (NetworkConfig memory) {
        if (networkConfig[chainId].vrfCoordinator != address(0)) {
            return networkConfig[chainId];
        } else if (chainId == LOCAL_CHAIN_ID) {
            return getAnvilConfig();
        } else {
            revert HelperConfig__InvalidChainId();
        }
    }

    function getSepoliaConfig() public pure returns (NetworkConfig memory) {
        return
            NetworkConfig({
                entryFee: 0.01 ether,
                interval: 30, //in second
                vrfCoordinator: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
                gasLane: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
                callbackGasLimit: 500000,
                subscriptionId: 0
            });
    }

    function getAnvilConfig() public returns (NetworkConfig memory) {
        if (LocalNetworkConfig.vrfCoordinator != address(0)) {
            return LocalNetworkConfig;
        }
        //first we deploy our v2_5 Mock to serve us the vrf for the anvil chain
        vm.startBroadcast();
        VRFCoordinatorV2_5Mock vrfCoordinatorMock = new VRFCoordinatorV2_5Mock(
            MOCK_BASE_FEE,
            MOCK_GAS_PRICE_LINK,
            MOCK_WEI_PER_UINT_LINK
        );
        vm.stopBroadcast();
        // we're making a Network config and saving it to the state variables
        LocalNetworkConfig = NetworkConfig({
            entryFee: 0.01 ether,
            interval: 30,
            callbackGasLimit: 500000,
            subscriptionId: 0,
            vrfCoordinator: address(vrfCoordinatorMock),
            //gasLane value doesn't matter
            gasLane: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae
        });
        return LocalNetworkConfig;
    }
    function getConfig() public returns (NetworkConfig memory) {
        return getConfigByChainId(block.chainid);
    }
}
