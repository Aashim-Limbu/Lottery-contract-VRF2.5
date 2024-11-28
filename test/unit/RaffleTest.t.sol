// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import {Test} from "forge-std/Test.sol";
import {DeployRaffle} from "@/script/Raffle.s.sol";
import {Raffle} from "../../src/Raffle.sol";
import {HelperConfig} from "@/script/HelperConfig.s.sol";

contract RaffleTest is Test {
    Raffle public raffle;
    HelperConfig public helperConfig;

    uint256 entryFee;
    uint256 interval;
    address vrfCoordinator;
    bytes32 gasLane;
    uint256 subscriptionId;
    uint32 callbackGasLimit;

    address public PLAYER = makeAddr("player");
    uint256 public constant STARTING_PLAYER_BALANCE = 10 ether;

    function setUp() external {
        DeployRaffle deployer = new DeployRaffle();
        (raffle, helperConfig) = deployer.deployContract();
        HelperConfig.NetworkConfig memory networkConfig = helperConfig
            .getConfig();
        entryFee = networkConfig.entryFee;
        interval = networkConfig.interval;
        vrfCoordinator = networkConfig.vrfCoordinator;
        gasLane = networkConfig.gasLane;
        subscriptionId = networkConfig.subscriptionId;
        callbackGasLimit = networkConfig.callbackGasLimit;
    }

    function testRaffleInitialization() public view {
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
    }

    function testRaffleMinimumFeeRevert() public {
        //Generally the test follows AAA format
        //Arrange
        vm.prank(PLAYER);
        //Act & Assert
        vm.expectRevert(Raffle.Raffle__InsufficientDeposit.selector);
        raffle.enterRaffle();
    }
}
