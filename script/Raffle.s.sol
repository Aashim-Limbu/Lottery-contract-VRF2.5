// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Raffle} from "src/Raffle.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {CreateSubscription, FundSubscription, AddConsumer} from "./Interaction.s.sol";

contract DeployRaffle is Script {
    Raffle public raffle;

    function run() public {
        deployContract();
    }

    function deployContract() public returns (Raffle, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        //initializing the network configuration before deploying the Raffle contract
        //First we don't have the deployed configuration for the Anvil test chain thus we're initializing the mock
        HelperConfig.NetworkConfig memory networkConfig = helperConfig
            .getConfig();
        if (networkConfig.subscriptionId == 0) {
            //1. create subscription in case the subscription id is 0
            // // 1. overwriting the newtorkConfig method like subscriptionId,vrfCoordinator to make sure it exists for anvil chain as well
            // // 2. createSubscription returns subscriptionId and vrf Coordinator Id
            CreateSubscription createSubscription = new CreateSubscription();
            (
                networkConfig.subscriptionId,
                networkConfig.vrfCoordinator
            ) = createSubscription.createSubscription(
                networkConfig.vrfCoordinator
            );
            //2. Fund It
            FundSubscription fundSubscription = new FundSubscription();
            fundSubscription.fundSubscription(
                networkConfig.vrfCoordinator,
                networkConfig.subscriptionId,
                networkConfig.link
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
        AddConsumer addConsumer = new AddConsumer();
        addConsumer.addConsumer(
            address(raffle),
            networkConfig.vrfCoordinator,
            networkConfig.subscriptionId
        );
        return (raffle, helperConfig);
    }
}
