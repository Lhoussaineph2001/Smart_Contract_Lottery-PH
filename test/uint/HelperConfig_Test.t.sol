//SPDX-License-Identifier:MIT

pragma solidity ^0.8.20;

import {Test, console2} from "forge-std/Test.sol";

import {Helperconfig} from "../../script/Helperconfig.s.sol";

contract Helperconfig_Test is Test {
    Helperconfig helper;

    address public vrfCoordinator;

    function setUp() public {
        helper = new Helperconfig();
    }

    

    /////////////////////////////////////////////////////////////////////////////////////////////

    //                         TEST   NETWORK CONFIG                                          ////

    /////////////////////////////////////////////////////////////////////////////////////////////


    function testNetworkConfig() public {

        if (block.chainid == 1) {

            vrfCoordinator = helper.MainnetETHConfig().vrfCoordinator;

            (, , address vrfCoordinator1, , , , ) = helper.Active_Network();

            assert(vrfCoordinator1 == vrfCoordinator);

        } else if (block.chainid == 1155111) {

            vrfCoordinator = helper.SepoliaETHConfig().vrfCoordinator;

            (, , address vrfCoordinator2,, , , ) = helper.Active_Network();


            assert(vrfCoordinator2 == vrfCoordinator);

        } else {

            vrfCoordinator = helper.getOrcreateanvilETHconfig().vrfCoordinator;
            
            (, , address vrfCoordinator3, ,, , ) = helper.Active_Network();

            assert(vrfCoordinator3 == vrfCoordinator);
        }
    }
}
