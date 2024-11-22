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
    //Events
    event VerifiedPlayer(address indexed player);

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
    }

    function enterRaffle() public payable {
        if (msg.value < i_entryFee) {
            revert Raffle__InsufficientDeposit();
        }
        s_players.push(payable(msg.sender));
        emit VerifiedPlayer(msg.sender);
    }

    function pickWinner() external  {
        if ((block.timestamp - s_lastTimeInvoked) < i_interval) {
            revert();
        }
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
    }
    function fulfillRandomWords(uint256 _requestId,uint256[] calldata _randomWords) internal override  {

    }

    //getter function
    function getEntranceFee() external view returns (uint256) {
        return i_entryFee;
    }
}
