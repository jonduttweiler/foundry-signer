// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {PermitToken} from "../src/PermitToken.sol";

contract PermitTokenScript is Script {
    function run() public returns (PermitToken token) {
        vm.startBroadcast();

        token = new PermitToken("Permit Token", "PTK", "1", 1_000_000 ether);

        vm.stopBroadcast();

        console.log("PermitToken deployed at:", address(token));
    }
}

