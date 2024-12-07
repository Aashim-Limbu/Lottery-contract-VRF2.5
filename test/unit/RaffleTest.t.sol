// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import {Test, console} from "forge-std/Test.sol";
import {DeployRaffle} from "@/script/Raffle.s.sol";
import {Raffle} from "../../src/Raffle.sol";
import {HelperConfig,CodeConstants} from "@/script/HelperConfig.s.sol";
import {Vm} from "forge-std/Vm.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

contract RaffleTest is Test , CodeConstants {
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

    /*//////////////////////////////////////////////////////////////
                              CHECKUPKEEPS
    //////////////////////////////////////////////////////////////*/
    function testcheckUpKeepReturnsFalseIfItHasNoBalance() public {
        //Arrange
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        //Act
        (bool upKeepNeeded, ) = raffle.checkUpkeep("");
        //Assert
        assert(!upKeepNeeded);
    }

    function testCheckUpKeepReturnsFalseIfRaffleIsntOpen() public {
        //Arrange
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entryFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        raffle.performUpkeep("");

        //Act
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        //assert
        assert(!upkeepNeeded);
    }

    function testCheckUpkeepReturnsFalseIfEnoughTimeHasntPassed() public {
        //Arrange
        vm.prank(PLAYER);
        //Act
        raffle.enterRaffle{value: entryFee}();
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        //Assert
        assert(!upkeepNeeded);
    }

    function testCheckUpkeepReturnsTrueWhenParametersGood() public {
        //Arrange
        vm.prank(PLAYER);
        //Act
        raffle.enterRaffle{value: entryFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        //Assign
        assert(upkeepNeeded);
    }

    /*//////////////////////////////////////////////////////////////
                             PERFORM UPKEEP
    //////////////////////////////////////////////////////////////*/
    modifier raffleEntered() {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entryFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        _;
    }

    function testPerformUpKeepOnlyRunsWhenCheckUpKeepIsTrue() public {
        //Arrage
        vm.prank(PLAYER);
        //Act
        raffle.enterRaffle{value: entryFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        //Assert
        raffle.performUpkeep("");
    }

    function testPerformUpkeepRevertIfCheckUpkeepIsFalse() public {
        //Arrange
        uint256 currentBalance = 0;
        uint256 numOfPlayers = 0;
        Raffle.RaffleState raffleState = raffle.getRaffleState();

        vm.prank(PLAYER);
        raffle.enterRaffle{value: entryFee}();
        currentBalance = currentBalance + entryFee;
        numOfPlayers = 1;
        // uint256 currentBalance =
        //Act && Assert
        vm.expectRevert(
            abi.encodeWithSelector(
                Raffle.Raffle__UpkeepNotNeeded.selector,
                currentBalance,
                numOfPlayers,
                raffleState
            )
        );
        raffle.performUpkeep("");
    }

    function testPerformUpkeepUpdateRaffleStateAndEmitsRequestId()
        public
        raffleEntered
    {
        //Act
        vm.recordLogs();
        raffle.performUpkeep(""); //every logs are recorded while performing the performUpkeep
        Vm.Log[] memory entries = vm.getRecordedLogs(); //https://book.getfoundry.sh/cheatcodes/record-logs?highlight=vm.recordlog#examples
        bytes32 requestId = entries[1].topics[1]; //thre first event [0] -> will be from the vrf itself.

        //Assert
        Raffle.RaffleState raffleState = raffle.getRaffleState();
        assert(uint256(requestId) > 0);
        assert(raffleState == Raffle.RaffleState.CALCULATING);
    }

    /*//////////////////////////////////////////////////////////////
                          FULFILL RANDOM WORDS
    //////////////////////////////////////////////////////////////*/
    modifier skipFork{ // since we're pretending to be vrf itself while calling the fulfill Random words it is erroring out
        if(block.chainid != LOCAL_CHAIN_ID){
            return ;
        }
        //if it is not the local_chain_id it just get return cause we can't pretend to be chainlink vrf node on the test net / forked net like sepolia
        //There are already real Chainlink VRF nodes working on the testnet and they are the one that can call the fulfillRandomWords.
        _;
    }
    function testIfFulfillRandomWordGetCalledOnlyAfterPerformUpkeep(
        uint256 randomRequestId
    ) public raffleEntered {
        //Arrange /Act /Assert
        vm.expectRevert(VRFCoordinatorV2_5Mock.InvalidRequest.selector);
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(
            randomRequestId,
            address(raffle)
        );
    }

    function testFulfillRandomWordPicksAWinnerResetAndSendsMoney()
        public
        raffleEntered
        skipFork
    {
        //Arrange
        uint256 additionalEntrants = 3;
        uint256 startingIndex = 1;
        // uint256(keccak256(abi.encode(1, 0))); --> 78541660797044910968829902406342334108369226379826116161446442989268089806461 % 4 = 1
        address expectedWinner = address(1);

        for (
            uint256 i = startingIndex;
            i < startingIndex + additionalEntrants;
            i++
        ) {
            //till 3 player we have 4 player with raffleEntered
            address newPlayer = address(uint160(i));
            hoax(newPlayer, 1 ether);
            raffle.enterRaffle{value: entryFee}();
        }
        uint256 startingTimeStamp = raffle.getLastTimeInvoked();
        uint256 winnerStartingBalance = expectedWinner.balance;
        //Act
        vm.recordLogs();
        raffle.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];
        //pretend to be chainlink vrf
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(
            uint256(requestId),
            address(raffle)
        );
        //Assert
        address recentWinner = raffle.getRecentWinner();
        Raffle.RaffleState raffleState = raffle.getRaffleState();
        uint256 winnerBalance = recentWinner.balance;
        uint256 endingTimeStamp = raffle.getLastTimeInvoked();
        uint256 prizeWon = entryFee * (additionalEntrants + 1); //4 players -->prize = 4 * entranceFee;

        assert(recentWinner == expectedWinner);
        assert(raffleState == Raffle.RaffleState.OPEN);
        assert(winnerBalance == winnerStartingBalance + prizeWon);
        assert(endingTimeStamp > startingTimeStamp);
    }
}
