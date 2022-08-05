// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import {Aggregator} from "../../contracts/Aggregator.sol";
import {TestHelpers} from "./TestHelpers.sol";

abstract contract TestParameters {}

contract AggregatorTest is TestParameters, TestHelpers {
    Aggregator public aggregator;

    function setUp() public {
        aggregator = new Aggregator();
    }

    function testAddFunction() public {}

    function testAddFunctionNotOwner() public {}

    function testRemoveFunction() public {}

    function testRemoveFunctionNotOwner() public {}
}
