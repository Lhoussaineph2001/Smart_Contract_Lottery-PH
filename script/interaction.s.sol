//SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { Helperconfig } from './Helperconfig.s.sol';
import { Script , console } from 'forge-std/Script.sol';
import {DevOpsTools} from 'lib/foundry-devops/src/DevOpsTools.sol';
import { VRFCoordinatorV2Mock } from '@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol';

contract CreateSubscription is Script {


   
    function run() public returns(uint64 subId){

        return createSubscriptionUsingConfig();

        
    }
       

    function createSubscriptionUsingConfig() public returns(uint64 subId){

        Helperconfig helperconfig = new Helperconfig();

        (,, address vrfCoordinator,,, , uint256  deployerkey) = helperconfig.Active_Network();
  
        return createSubscription_I(vrfCoordinator , deployerkey);
    }


    function createSubscription_I( address vrfCoordinator , uint256  deployerkey) public returns(uint64) {

        vm.startBroadcast(deployerkey);
        
        uint64 subId = VRFCoordinatorV2Mock(vrfCoordinator).createSubscription();
        
        vm.stopBroadcast();
        
        return subId;

    }

 
}

contract FundSubcription is Script {

        uint96 public constant FUND_AMOUT = 3 ether;  // 3 link each run

        function run() external {

            fundSubscriptionUsingConfig();

        }
    
       function fundSubscriptionUsingConfig() public {

        Helperconfig helperconfig = new Helperconfig();

        (,, address vrfCoordinator,,uint64 subId,,  uint256  deployerkey)  = helperconfig.Active_Network();
  
         fundSubscription(subId,vrfCoordinator  ,deployerkey);

       }


       function fundSubscription(uint64 subId , address vrfCoordinator   ,uint256 deployerkey) public  {


        if (block.chainid == 31337){ // 31337 => anvil running
        
        vm.startBroadcast(deployerkey);
        
        VRFCoordinatorV2Mock(vrfCoordinator).fundSubscription(subId,FUND_AMOUT);

        vm.stopBroadcast();

        }else {

            

        }
    }

}

contract AddConsumer is Script {

    function run() external {

        address raffle = DevOpsTools.get_most_recent_deployment("Raffle",block.chainid);

        addConsumerUsingConfig(raffle);
    }

    function addConsumerUsingConfig(address raffle) public {
 
         Helperconfig helperconfig = new Helperconfig();

        (,, address vrfCoordinator,,uint64 subId,, uint256  deployerkey) = helperconfig.Active_Network();
  
        addConsumer(raffle,vrfCoordinator,subId ,  deployerkey);
    }

    function addConsumer(address raffle , address vrfCoordinator , uint64 subId , uint256 deployerkey) public {

        vm.startBroadcast(deployerkey);
        
        VRFCoordinatorV2Mock(vrfCoordinator).addConsumer(subId,raffle);

        vm.stopBroadcast();

    }
}