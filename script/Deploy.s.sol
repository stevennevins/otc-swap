// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import {OverTheCounter} from "src/OverTheCounter.sol";

contract Deploy is Script {
    OverTheCounter public otc;

    function run() public {
        vm.broadcast();
        otc = new OverTheCounter();
    }
}
