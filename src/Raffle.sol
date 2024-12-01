// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;
import {VRFConsumerBaseV2Plus} from "@chainlink/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

/**
 * @title Raffle Contract
 * @author Aashim Limbu
 * @notice Creating a simple Lottery system
 * @dev Implements ChainLink VRF @v2.5
 */

contract Raffle is VRFConsumerBaseV2Plus {
    //Errors
    error Raffle__InsufficientDeposit();
    error Raffle__TransferFailed();
    error Raffle__NotOpen();
    error Raffle__UpkeepNotNeeded(
        uint256 balance,
        uint256 playerLength,
        RaffleState raffleState
    );
    //Enums
    enum RaffleState {
        OPEN,
        CALCULATING
    }

    //State Variables
    uint16 constant REQUEST_CONFIRMATION = 3;
    uint16 constant Num_WORDS = 1;
    uint256 private immutable i_entryFee;
    uint256 private immutable i_interval;
    bytes32 private immutable i_keyHash;
    uint256 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;
    address payable[] private s_players;
    uint256 private s_lastTimeInvoked;
    address payable private s_recentWinner;
    RaffleState private s_raffleState;
    //Events
    event VerifiedPlayer(address indexed player);
    event WinnerPicked(address indexed winner);
    event RequestedRaffleWinner(uint256 indexed requestId);

    constructor(
        uint256 entryFee,
        uint256 _interval,
        address vrfCoordinator,
        bytes32 _gasLane,
        uint256 _subscriptionId,
        uint32 _callbackGasLimit
    ) VRFConsumerBaseV2Plus(vrfCoordinator) {
        //we need to pass the constructor argument from the children's constructor .
        i_entryFee = entryFee;
        i_interval = _interval;
        i_keyHash = _gasLane;
        i_callbackGasLimit = _callbackGasLimit;
        i_subscriptionId = _subscriptionId;
        s_lastTimeInvoked = block.timestamp;
        s_raffleState = RaffleState.OPEN;
    }

    function enterRaffle() public payable {
        if (msg.value < i_entryFee) {
            revert Raffle__InsufficientDeposit();
        }
        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle__NotOpen();
        }
        s_players.push(payable(msg.sender));
        emit VerifiedPlayer(msg.sender);
    }

    /**
     * @dev This is the function that the Chainlink Keeper nodes call
     * they look for `upkeepNeeded` to return True.
     * the following should be true for this to return true:
     * 1. The time interval has passed between raffle runs.
     * 2. The lottery is open.
     * 3. The contract has ETH.
     * 4. There are players registered.
     * 5. Implicity, your subscription is funded with LINK.
     */
    function checkUpkeep(
        bytes memory
    ) public view returns (bool upkeepNeeded, bytes memory) {
        bool hasTimePassed = (block.timestamp - s_lastTimeInvoked) >=
            i_interval;
        bool isContractOpen = s_raffleState == RaffleState.OPEN;
        bool hasBalance = address(this).balance > 0;
        bool hasPlayers = s_players.length > 0;
        upkeepNeeded =
            hasTimePassed &&
            isContractOpen &&
            hasBalance &&
            hasPlayers; //it returns automatically no need to write return upkeepNeeded
        return (upkeepNeeded, "");
    }

    function performUpkeep(bytes calldata /* performData */) external {
        //
        (bool upkeepNeeded, ) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert Raffle__UpkeepNotNeeded(
                address(this).balance,
                s_players.length,
                RaffleState.OPEN
            );
        }
        s_raffleState = RaffleState.CALCULATING;
        //generate random words then
        VRFV2PlusClient.RandomWordsRequest memory request = VRFV2PlusClient
            .RandomWordsRequest({
                keyHash: i_keyHash, //keyHash which stand for some gasoline for some gasprice to work with chainlink node
                subId: i_subscriptionId, //how we fund the oracle gas while working with chainlink vrf
                requestConfirmations: REQUEST_CONFIRMATION, //how many block should we wait
                callbackGasLimit: i_callbackGasLimit, // boundry so that we don't expend too much gas on the callback
                numWords: Num_WORDS, //how many random number we want
                extraArgs: VRFV2PlusClient._argsToBytes(
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
                )
            });
        uint256 requestId = s_vrfCoordinator.requestRandomWords(request);
        //this is redundant/ unnecessary since it is emitted in the requestRandomWords as well
        emit RequestedRaffleWinner(requestId);
    }

    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] calldata randomWords
    ) internal override {
        //Effects Internal Contract State
        //we recieve random words in array so picking up the first element
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable recentWinner = s_players[indexOfWinner];
        s_recentWinner = recentWinner;
        s_raffleState = RaffleState.OPEN;
        s_players = new address payable[](0);
        s_lastTimeInvoked = block.timestamp;
        emit WinnerPicked(recentWinner);

        //Interactions (External Contract Interactions)
        (bool sent, ) = recentWinner.call{value: address(this).balance}("");
        if (!sent) {
            revert Raffle__TransferFailed();
        }
    }

    //getter function
    function getEntranceFee() external view returns (uint256) {
        return i_entryFee;
    }

    function getRaffleState() public view returns (RaffleState) {
        return s_raffleState;
    }
    function getPlayerWithIndex(uint256 idx)  public view returns(address) {
        return s_players[idx];
    }
    function getLastTimeInvoked() public view returns(uint256){
        return s_lastTimeInvoked;
    }
    function getRecentWinner()public view returns(address){
        return s_recentWinner;
    }
}
