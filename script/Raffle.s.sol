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
        ///Straight to point if it is deployed on the sepolia chain it just returns the network config
        //Else for the anvil chain, we kind of deploy our mock and then assign them to vrfCoordinator address and then eventually it get returns 
        HelperConfig.NetworkConfig memory networkConfig = helperConfig.getConfig();
        if (networkConfig.subscriptionId == 0) {
            //1. Create Subscription incase the Subscription id is 0.
            //      // 1. overwriting the newtorkConfig method like subscriptionId,vrfCoordinator to make sure it exists for anvil chain as well .
            //      // 2. createSubscription returns subscriptionId and vrf Coordinator Id .
            CreateSubscription createSubscription = new CreateSubscription();
            ( networkConfig.subscriptionId, networkConfig.vrfCoordinator ) = createSubscription.createSubscription( networkConfig.vrfCoordinator, networkConfig.account );
            //2. Fund It .
            FundSubscription fundSubscription = new FundSubscription();
            fundSubscription.fundSubscription(
                networkConfig.vrfCoordinator,
                networkConfig.subscriptionId,
                networkConfig.link,
                networkConfig.account
            );
        }
        vm.startBroadcast(networkConfig.account);
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
            networkConfig.subscriptionId,
            networkConfig.account
        );
        return (raffle, helperConfig);
    }
}
