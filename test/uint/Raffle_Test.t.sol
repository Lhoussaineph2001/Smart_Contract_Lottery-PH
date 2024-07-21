//SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";
import {Deploy_Raffle} from "../../script/Deploy_Raffle.s.sol";
import {Raffle} from "../../src/Raffle.sol";
import {Helperconfig} from "../../script/Helperconfig.s.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";

contract Raffle_test is Test {
    event EnteredRaffle(address indexed player); // should be the same event of raffle
    address public immutable PLAYER = makeAddr("Lhoussaine Ph");
    uint256 public constant PLAYER_VALUE = 10 ether;

    uint256 entrancefee;
    uint256 interval;
    address vrfCoordinator;
    bytes32 gasLane ;
    uint64 subscriptionId;
    uint32 callbackGasLimit;
    uint256 deployerkey;

    Raffle raffle;
    Helperconfig helperconfig;

    function setUp() public {
        Deploy_Raffle deploy_raffle = new Deploy_Raffle();

        (raffle, helperconfig) = deploy_raffle.run();

        (
            entrancefee,
            interval,
            vrfCoordinator,
            gasLane,
            subscriptionId,
            callbackGasLimit,
            deployerkey
        ) = helperconfig.Active_Network();

        vm.deal(PLAYER, PLAYER_VALUE);
    }


    /////////////////////
    // Modifier /////////
    ////////////////////

        modifier UpkeepisTrue() {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entrancefee}();
        vm.warp(block.timestamp + interval); // set timestamp
        vm.roll(block.number + 1); // incriment  the block to next block for new deploy => rafflestate = OPEN

        _;
    }


    ///////////////////
    // Intialization //
    ///////////////////

    function testinitializeRaffleState() public view {
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
    }

    ////////////////////
    // Not Enough ETH //
    ////////////////////

    function testNotEnoughEth() public {
        vm.prank(PLAYER);

        vm.expectRevert(Raffle.Raffle__NotEnoughEthSend.selector);
        raffle.enterRaffle();
    }

    /////////////////////////////////////////////////////////////////////////////////////////////

    //                         TEST   FOUNCTIONS                                             ////

    /////////////////////////////////////////////////////////////////////////////////////////////


    /////////////////
    // EnterRaffle //
    /////////////////

    function testRafflerecordPlalerswhentheyEnter() public {
        vm.prank(PLAYER);

        raffle.enterRaffle{value: entrancefee}();
        address player1 = raffle.getplayer(0);
        assert(PLAYER == player1);
    }

    ///////////
    // Event //
    ///////////

    function testEventinenterRaffle() public {
        vm.prank(PLAYER);

        vm.expectEmit(
            true, // true because we have an pramitter here : address player
            false, // we don't have any param here
            false,
            false,
            address(raffle) // address of event wich mean's address of raffle
        );

        emit EnteredRaffle(PLAYER);
        raffle.enterRaffle{value: entrancefee}();
    }

    ///////////////////
    // performUpkeep //
    ///////////////////

    function testRaffleStateCalculating() public UpkeepisTrue {
        raffle.performUpkeep("");

        vm.expectRevert(Raffle.Raffle__RaffleNotOpen.selector);
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entrancefee}();
    }

    //////////////////
    // checkUpkeep ///
    //////////////////

    function testCheckUpReturnFalseIfNotBalance() public {
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        (bool upkeep, ) = raffle.checkUpkeep("");

        assert(!upkeep);
    }

    function testCheckUpReturnFalseIfNotOPEN() public UpkeepisTrue {
        raffle.performUpkeep("");

        (bool upkeep, ) = raffle.checkUpkeep("");

        assert(upkeep == false);
    }

    function testCheckUpReturnFalseIfTimePasse() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entrancefee}();

        vm.warp(raffle.getlastTimeStamp());
        vm.roll(block.number + 1);

        (bool upkeep, ) = raffle.checkUpkeep("");

        assert(upkeep == false);
    }

    ///////////////////
    // performUpkeep //
    ///////////////////

    function testperformUpkeePassifupkeepisTrue() public UpkeepisTrue {
        raffle.performUpkeep("");
    }

    function testperformUpkeepRevertifupkeepisFalse() public {
        uint256 currentBalnce = 0;
        uint256 num_players = 0;
        uint256 raffle_state = 0;
        // expected error with param
        vm.expectRevert(
            abi.encodeWithSelector(
                Raffle.Raffle__UpkeepNtNeeded.selector,
                currentBalnce,
                num_players,
                raffle_state
            )
        );

        raffle.performUpkeep("");
    }

    function testperformUpkeepEmitsRequestId() public UpkeepisTrue {
        vm.recordLogs(); // return all the data in event

        raffle.performUpkeep("");

        Vm.Log[] memory entries = vm.getRecordedLogs(); // getting all the data and store it in logs array
        bytes32 requestId = entries[1].topics[1];

        // entries[1] => second eventbecause the first exist in the mocks contract
        // topics[1] => indexed requestId , [0] => all the event

        assert(uint256(requestId) > 0); // just make sure that's is working
    }

    ////////////////////////
    // fulfillRandomWords //
    ////////////////////////

    function testFulfillRandomWordsCanOnlyBeCalledAfterPerformUpkeep(
        uint256 randomRequest
    ) public UpkeepisTrue {

        vm.expectRevert("nonexistent request");

        VRFCoordinatorV2Mock(vrfCoordinator).fulfillRandomWords(
            randomRequest,
            address(raffle)
        );
    }

    function testfulfillRandomWordsPickAwinnerAndResetsAndSendMoney()
        public
        UpkeepisTrue
    {

        for (uint160 i = 1; i < 5; i++) {
            hoax(address(i), PLAYER_VALUE);
            raffle.enterRaffle{value: entrancefee}();
        }

        uint256 prize = entrancefee * 5;

        vm.recordLogs();

        raffle.performUpkeep("");

        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];

        VRFCoordinatorV2Mock(vrfCoordinator).fulfillRandomWords(
            uint256(requestId),
            address(raffle)
        );

        uint256 Winner_balance = raffle.getRecentwinner().balance;
        console.log(PLAYER_VALUE + prize - entrancefee);
        console.log(Winner_balance);

        assert(Winner_balance == PLAYER_VALUE + prize - entrancefee);
    }


}
