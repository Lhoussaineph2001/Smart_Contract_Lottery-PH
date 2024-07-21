//SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { Script ,console} from 'forge-std/Script.sol';
import { Raffle } from '../src/Raffle.sol';
import { Helperconfig } from './Helperconfig.s.sol';
import { CreateSubscription ,  AddConsumer ,FundSubcription} from './interaction.s.sol';

contract Deploy_Raffle is Script {

    function run() external returns (Raffle raffle , Helperconfig) {

        Helperconfig helperconfig = new Helperconfig();

        (
            
        uint256 entrancefee,
        uint256 interval,
        address vrfCoordinator ,
        bytes32 gasLane ,
        uint64 subscriptionId,
        uint32 callbackGasLimit,
        uint256 deployerkey
        
        )  = helperconfig.Active_Network();

        if ( subscriptionId == 0 ){

            // create  a subscription 
            CreateSubscription createsubscription = new CreateSubscription();
            subscriptionId = createsubscription.createSubscription_I(vrfCoordinator ,deployerkey);
            // found it 
            FundSubcription fundsubcription = new FundSubcription();

            fundsubcription.fundSubscription( subscriptionId , vrfCoordinator, deployerkey);

           

          


        }

        vm.startBroadcast();

        raffle = new Raffle(  
            
        entrancefee,
        interval,
        vrfCoordinator ,
        gasLane ,
        subscriptionId,
        callbackGasLimit,
        deployerkey
        
        );

        vm.stopBroadcast();

        AddConsumer addConsumer = new AddConsumer();

        addConsumer.addConsumer(address(raffle),vrfCoordinator,subscriptionId,deployerkey);

        return (raffle,helperconfig);

    }

}