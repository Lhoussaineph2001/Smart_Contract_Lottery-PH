// SPDX-License-Identifier:MIT

pragma solidity ^0.8.20;

/** 
 * @title A simple Raffle Contract
 * @author Lhoussaine Ait Aissa
 * @notice This contract is for creating a simple raffle
 * @dev Implement Chainlink VRFv2
*/

import  { VRFCoordinatorV2Interface } from '@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol';

import  { VRFConsumerBaseV2 } from '@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol';

contract Raffle is VRFConsumerBaseV2{

      ///////////////////
     // Errors       //
    //////////////////

    error Raffle__NotEnoughEthSend();
    error Raffle__TransferFail();
    error Raffle__RaffleNotOpen();
    error Raffle__UpkeepNtNeeded(uint256 current_balance , uint256 num_players , uint256 raffle_state);


    //////////////////////////////
    // Type Declarations       //
    ////////////////////////////

    enum  RaffleState {
         OPEN,      // 0
        CALCULATING // 1
    
    }


    ////////////////////////////
    // State Variables       //
    //////////////////////////

    uint16 private constant REQUEST_CONFIRMATIONS = 3; 
    uint32 private constant NUM_WORDS = 1; 

    uint256 private immutable i_entranceFee;
    uint256 private immutable i_deployerkey;
    uint256 private immutable i_interval;
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    bytes32 private immutable i_gasLane;
    uint64 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;
  

    uint256 private s_lastTimeStamp;
    address payable [] private s_players;
    address private  s_recentWinner;
    RaffleState private s_RaffleState ;


      //////////////////
     // Events       //
    //////////////////

    event EnteredRaffle(address indexed player );
    event PickedWinner(address indexed winner );
    event RequestIdRaffleWinner(uint256 indexed requestId  );

    constructor (
        
        uint256 entrancefee ,
        uint256 interval,
        address vrfCoordinator , 
        bytes32 gasLane , 
        uint64 subscriptionId,
        uint32 callbackGasLimit,
        uint256 deployerkey
        
        ) VRFConsumerBaseV2(vrfCoordinator) 
        {
        //@audit zero check address for vrf
        i_entranceFee = entrancefee;
        i_interval = interval;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinator);
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;

        s_RaffleState = RaffleState.OPEN; // defaulte raffle 

        s_lastTimeStamp = block.timestamp;
        i_deployerkey= deployerkey;
        
        }


    function enterRaffle() public payable {

        if ( msg.value < i_entranceFee) {
            revert Raffle__NotEnoughEthSend();
        }

        if (s_RaffleState != RaffleState.OPEN){

            revert Raffle__RaffleNotOpen();
        }

        s_players.push(payable(msg.sender));

        emit EnteredRaffle(msg.sender);
        
        }

/**
* @dev This is the function that the Chainlink Automation nodes 
* call to see if it's  to perform an upkeep.
*  The following should be true for this to return true :
*  1. The time interval has passed between raffle runs 
*  2. The Raffle is in the open state 
*  3. The contract ETH (aka , players)
*  4. (Implicit) the subscription is funded with Link (Link faucet in Chainlink) 
* @return upkeepNeeded
*/

        function checkUpkeep(
             bytes memory /** check Data  */
             ) public view returns( bool upkeepNeeded , bytes memory perforData ){

                bool Timepassed = (block.timestamp - s_lastTimeStamp) >= i_interval;
                bool isOpen = s_RaffleState == RaffleState.OPEN;
                bool hasBalance  = address(this).balance > 0;
                bool hasplayers = s_players.length > 0;

                upkeepNeeded = (Timepassed && isOpen && hasBalance && hasplayers);

                return (upkeepNeeded, "0x0");

             }

        function performUpkeep( bytes calldata  /** performData  */) external  {

         (bool upkeepNeeded,) = checkUpkeep("");

         if(!upkeepNeeded) {

            revert Raffle__UpkeepNtNeeded( 
                address(this).balance,
                s_players.length,
                uint256(s_RaffleState)
            );
         }

        s_RaffleState = RaffleState.CALCULATING;

       uint256 requestId =  i_vrfCoordinator.requestRandomWords(

        i_gasLane ,
        i_subscriptionId ,
        REQUEST_CONFIRMATIONS,
        i_callbackGasLimit ,
        NUM_WORDS

        );

        emit RequestIdRaffleWinner(requestId);



        }
 
        // CFI  : Checks Effects Interactions
        function fulfillRandomWords( 
             uint256 /** requestId */,
             uint256 [] memory randomWords
             ) internal override {

            // palyers = 10
            // rnd =  12
            // winner = 12%10 -> 2

            // Checks require(error) ..
            //Effects ( Our own Contract)
            uint256 indexWinner = randomWords[0] % s_players.length;

            address payable winner = s_players[indexWinner];

            s_recentWinner = winner;

            s_RaffleState = RaffleState.OPEN;

            s_players = new address payable[](0); // restart array of players , start new game 

            s_lastTimeStamp = block.timestamp;

            emit PickedWinner(winner);

            // Interactions ( Other Contarcts)
            (bool success ,) = winner.call{value : address(this).balance}("");

            if (!success) {

                revert Raffle__TransferFail();

            }


          


        }

    /** Getters Funs */

        function getPlayers() external view returns(uint256) {

        return s_players.length;

        } 

        function getplayer(uint256 id ) external view returns(address payable ) {

        return s_players[id];

        } 
        
        function getRecentwinner() external view returns(address) {

        return s_recentWinner ;

        } 

        

        function getRaffleState() external view returns(RaffleState) {

        return s_RaffleState;

        } 

        function getlastTimeStamp() external view returns(uint256) {

        return s_lastTimeStamp;

        } 

}