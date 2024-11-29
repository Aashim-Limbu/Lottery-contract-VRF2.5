// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import {Test, console} from "forge-std/Test.sol";
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

    event VerifiedPlayer(address indexed player);
    event WinnerPicked(address indexed winner);

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
        console.log(vrfCoordinator);
        vm.deal(PLAYER, STARTING_PLAYER_BALANCE);
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

    function testRafflePlayerWhenTheyEnter() public {
        //Arrange
        vm.prank(PLAYER);
        //Act
        raffle.enterRaffle{value: entryFee}();
        //Assert
        address recordedPlayer = raffle.getPlayerWithIndex(0);
        assert(PLAYER == recordedPlayer);
    }

    function testRaffleEnterEvent() public {
        //Arrange
        vm.prank(PLAYER);
        //Act
        vm.expectEmit(true, false, false, false, address(raffle));
        emit VerifiedPlayer(PLAYER);
        //Assert
        raffle.enterRaffle{value: entryFee}();
    }

    function testRestrictPlayerBasedOnRaffleState() public {
        //Arrange
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entryFee}();
        //How to wait for the interval since we have the player and the balance ready in the contract
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        raffle.performUpkeep("");
        //Act //Asserts
        vm.expectRevert(Raffle.Raffle__NotOpen.selector);
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entryFee}();
    }
}
