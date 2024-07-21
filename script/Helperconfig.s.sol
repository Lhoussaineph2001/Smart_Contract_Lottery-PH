//SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { Script , console} from 'forge-std/Script.sol';

import { VRFCoordinatorV2Mock } from '@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol';

contract Helperconfig is Script {

    NetworkConfig public  Active_Network;


    uint256 private constant SEPOLIA_CHAINID = 11155111 ;
    uint96  public constant BASEFEE = 0.25 ether ; // 0.25 Link 
    uint96 public constant GASPRICELINK = 1e9; // 1 gwei Link 
    uint256 public constant DEFAULT_ANVIL_PRIVATE_KEY = 0x7c852118294e51e653712a81e05800f419141751be58f605c371e15141b007a6; // private key in anvil account 

    struct NetworkConfig {

        uint256 entrancefee;
        uint256 interval;
        address vrfCoordinator ;
        bytes32 gasLane ;
        uint64 subscriptionId;
        uint32 callbackGasLimit;
        uint256 deployerkey;

    }

    constructor(){

        if (block.chainid == 1) {

            Active_Network  = MainnetETHConfig();
        } else if ( block.chainid ==  SEPOLIA_CHAINID){

            Active_Network = SepoliaETHConfig();

        } else {

            Active_Network = getOrcreateanvilETHconfig();

        }
    }


    function SepoliaETHConfig() public view returns( NetworkConfig memory ) {
        
         return NetworkConfig(
            {
            
         entrancefee : 0.1 ether ,
         interval  : 30 , // 30s
         vrfCoordinator  : 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 , // In VRF Sepolia test  exist
         gasLane  : bytes32(0) ,
         subscriptionId  : 0 ,
         callbackGasLimit  : 500000, // 500,000 gas
         deployerkey : vm.envUint("PRIVATE_KEY") // call the private key in env file
            }
         );

    }


    function MainnetETHConfig() public view returns( NetworkConfig memory ) {
        
         return NetworkConfig(
            {
            
         entrancefee : 0.2 ether ,
         interval  : 30 , // 30s
         vrfCoordinator  : 0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65,
         gasLane  :bytes32(0)  ,
         subscriptionId  : 0 ,
         callbackGasLimit  : 400000,
         deployerkey : vm.envUint("PRIVATE_KEY") // Mainnet private key 
            }
         );

    }

    function getOrcreateanvilETHconfig() public  returns(NetworkConfig memory ){

        if ( Active_Network.vrfCoordinator != address(0) ){

            return Active_Network;

        }

        vm.startBroadcast();

        VRFCoordinatorV2Mock anvilMock  = new VRFCoordinatorV2Mock( BASEFEE , GASPRICELINK );

        vm.stopBroadcast();

 
        return NetworkConfig(
            {
         
         entrancefee : 0.1 ether ,
         interval  : 30 , // 30s
         vrfCoordinator  : address(anvilMock),  
         gasLane  : bytes32(0) ,
         subscriptionId  : 0 , // Our script will add this ! 
         callbackGasLimit  : 500000,
         deployerkey : DEFAULT_ANVIL_PRIVATE_KEY

            }
            
        );

    }

}