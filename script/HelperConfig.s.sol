// SPDX-License-Identifier: MIT
import {Script} from "forge-std/Script.sol";
pragma solidity >=0.8.0 <0.9.0;


abstract contract CodeConstants {
    uint256 public constant EHT_SEPOLIA_CHAIN_ID = 11155111;
    uint256 public constant LOCAL_CHAIN_ID = 31337;
}
contract HelperConfig is CodeConstants,Script {
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
    function getConfigByChainId(uint256 chainId) public  returns (NetworkConfig memory) {
        if(networkConfig[chainId].vrfCoordinator != address(0)){
            return networkConfig[chainId];
        }else if(chainId == LOCAL_CHAIN_ID){
            //getOrCreateAnvilChainEthConfig()
        }else{
            revert HelperConfig__InvalidChainId();
        }
    }
    function getSepoliaConfig() public pure returns (NetworkConfig memory) {
        return
            NetworkConfig({
                entryFee: 0.01 ether,
                interval: 30,//in second
                vrfCoordinator: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
                gasLane: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
                callbackGasLimit: 500000,
                subscriptionId: 0
            });
    }
}
