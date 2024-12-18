// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import {Script, console} from "forge-std/Script.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";
import {HelperConfig, CodeConstants} from "script/HelperConfig.s.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "test/mocks/LinkToken.sol";

contract CreateSubscription is Script {
    function CreateSubscriptionUsingConfig() public returns (uint256, address) {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        address vrfCoordinator = config.vrfCoordinator;
        address account = config.account;
        //create subscription
        (uint256 subId, ) = createSubscription(vrfCoordinator, account);
        return (subId, vrfCoordinator);
    }

    function createSubscription(
        address vrfCoordinator,
        address account
    ) public returns (uint256, address) {
        console.log("Creating the subscriptionon chainId: ", block.chainid);
        vm.startBroadcast(account);
        uint256 subId = VRFCoordinatorV2_5Mock(vrfCoordinator)
            .createSubscription();
        vm.stopBroadcast();
        console.log("Your subscription id is: ", subId);
        return (subId, vrfCoordinator);
    }

    function run() public {
        console.log("Hi from Create SUbscription");
        CreateSubscriptionUsingConfig();
    }
}

//Programatically funding a subscription
contract FundSubscription is Script, CodeConstants {
    uint256 public constant FUND_AMOUNT = 3 ether; //equivalent to LINK 3 LINK

    function fundSubscriptionUsingConfig() public {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        address vrfCoordinator = config.vrfCoordinator;
        uint256 subscriptionId = config.subscriptionId;
        address linkToken = config.link;
        address account = config.account;
        fundSubscription(vrfCoordinator, subscriptionId, linkToken, account);
    }

    function fundSubscription(
        address vrfCoordinator,
        uint256 subscriptionId,
        address linkToken,
        address account
    ) public {
        console.log("funding subscription: ", subscriptionId);
        console.log("VRF coordinator : ", vrfCoordinator);
        console.log("On ChainId : ", block.chainid);
        if (block.chainid == LOCAL_CHAIN_ID) {
            vm.startBroadcast();
            //invoking the fund subscription to mimic the funding of the subscription for anvil chain
            VRFCoordinatorV2_5Mock(vrfCoordinator).fundSubscription(
                subscriptionId,
                FUND_AMOUNT * 100
            );
            vm.stopBroadcast();
        } else {
            //We've seen that during funding a subscription the transfer And Call function get invoked.
            //for sepolia
            vm.startBroadcast(account);
            //linkToken address we got from the chainlink itself // Link Token contracts https://docs.chain.link/resources/link-token-contracts
            LinkToken(linkToken).transferAndCall(
                vrfCoordinator,
                FUND_AMOUNT,
                abi.encode(subscriptionId)
            );
            vm.stopBroadcast();
        }
    }

    function run() public {
        fundSubscriptionUsingConfig();
    }
}

//programatically adding a consumer
contract AddConsumer is Script {
    function addConsumerUsingConfig(address mostRecentDeployedContract) public {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory netConfig = helperConfig.getConfig();
        uint256 subId = netConfig.subscriptionId;
        address vrfCoordinator = netConfig.vrfCoordinator;
        address account = netConfig.account;
        addConsumer(mostRecentDeployedContract, vrfCoordinator, subId, account);
    }

    function addConsumer(
        address contractToAddtoVrf,
        address vrfCoordinator, 
        uint256 subId,
        address account
    ) public {
        vm.startBroadcast(account);
        VRFCoordinatorV2_5Mock(vrfCoordinator).addConsumer(
            subId,
            contractToAddtoVrf
        );
        vm.stopBroadcast();
    }

    function run() external {
        address mostRecentDeployment = DevOpsTools.get_most_recent_deployment(
            "Raffle",
            block.chainid
        );
        console.log("Hi from Add consumer ");
        addConsumerUsingConfig(mostRecentDeployment);
    }
}
