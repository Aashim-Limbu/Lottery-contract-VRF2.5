// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Raffle} from "src/Raffle.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {CreateSubscription} from "./Interaction.s.sol";

contract DeployRaffle is Script {
    Raffle public raffle;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();
        // raffle = new Raffle(5e16);
        vm.stopBroadcast();
    }

    function deployContract() public returns (Raffle, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        //initializing the network configuration before deploying the Raffle contract
        //First we don't have the deployed configuration for the Anvil test chain thus we're initializing the mock
        HelperConfig.NetworkConfig memory networkConfig = helperConfig
            .getConfig();
        if (networkConfig.subscriptionId == 0) {
            //create subscription in case the subscription id is 0
            CreateSubscription createSubscription = new CreateSubscription();
            //overwriting the newtorkConfig method like subscriptionId,vrfCoordinator to make sure it exists for anvil chain as well
            //createSubscription returns subscriptionId and vrf Coordinator Id
            (
                networkConfig.subscriptionId,
                networkConfig.vrfCoordinator
            ) = createSubscription.createSubscription(
                networkConfig.vrfCoordinator
            );
        }
        vm.startBroadcast();
        raffle = new Raffle(
            networkConfig.entryFee,
            networkConfig.interval,
            networkConfig.vrfCoordinator,
            networkConfig.gasLane,
            networkConfig.subscriptionId,
            networkConfig.callbackGasLimit
        );
        vm.stopBroadcast();
        return (raffle, helperConfig);
    }
}
//
