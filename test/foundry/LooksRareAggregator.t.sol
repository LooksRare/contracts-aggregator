// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import {LooksRareAggregator} from "../../contracts/LooksRareAggregator.sol";
import {LooksRareProxy} from "../../contracts/proxies/LooksRareProxy.sol";
import {TokenRescuer} from "../../contracts/TokenRescuer.sol";
import {ILooksRareAggregator} from "../../contracts/interfaces/ILooksRareAggregator.sol";
import {BasicOrder} from "../../contracts/libraries/OrderStructs.sol";
import {OwnableTwoSteps} from "@looksrare/contracts-libs/contracts/OwnableTwoSteps.sol";
import {MockERC20} from "./utils/MockERC20.sol";
import {TestHelpers} from "./TestHelpers.sol";
import {TokenRescuerTest} from "./TokenRescuer.t.sol";

abstract contract TestParameters {
    address internal constant LOOKSRARE_V1 = 0x59728544B08AB483533076417FbBB2fD0B17CE3a;
    address internal constant _notOwner = address(1);
}

contract LooksRareAggregatorTest is TestParameters, TestHelpers, TokenRescuerTest, ILooksRareAggregator {
    LooksRareAggregator aggregator;
    LooksRareProxy looksRareProxy;
    TokenRescuer tokenRescuer;

    function setUp() public {
        aggregator = new LooksRareAggregator();
        tokenRescuer = TokenRescuer(address(aggregator));
        looksRareProxy = new LooksRareProxy(LOOKSRARE_V1);
    }

    function testAddFunction() public {
        assertTrue(!aggregator.supportsProxyFunction(address(looksRareProxy), LooksRareProxy.buyWithETH.selector));
        vm.expectEmit(true, true, false, true);
        emit FunctionAdded(address(looksRareProxy), LooksRareProxy.buyWithETH.selector);
        aggregator.addFunction(address(looksRareProxy), LooksRareProxy.buyWithETH.selector);
        assertTrue(aggregator.supportsProxyFunction(address(looksRareProxy), LooksRareProxy.buyWithETH.selector));
    }

    function testAddFunctionNotOwner() public {
        vm.prank(_notOwner);
        vm.expectRevert(OwnableTwoSteps.NotOwner.selector);
        aggregator.addFunction(address(looksRareProxy), LooksRareProxy.buyWithETH.selector);
    }

    function testRemoveFunction() public {
        assertTrue(!aggregator.supportsProxyFunction(address(looksRareProxy), LooksRareProxy.buyWithETH.selector));
        aggregator.addFunction(address(looksRareProxy), LooksRareProxy.buyWithETH.selector);
        assertTrue(aggregator.supportsProxyFunction(address(looksRareProxy), LooksRareProxy.buyWithETH.selector));

        vm.expectEmit(true, true, false, true);
        emit FunctionRemoved(address(looksRareProxy), LooksRareProxy.buyWithETH.selector);
        aggregator.removeFunction(address(looksRareProxy), LooksRareProxy.buyWithETH.selector);
        assertTrue(!aggregator.supportsProxyFunction(address(looksRareProxy), LooksRareProxy.buyWithETH.selector));
    }

    function testRemoveFunctionNotOwner() public {
        aggregator.addFunction(address(looksRareProxy), LooksRareProxy.buyWithETH.selector);

        vm.prank(_notOwner);
        vm.expectRevert(OwnableTwoSteps.NotOwner.selector);
        aggregator.removeFunction(address(looksRareProxy), LooksRareProxy.buyWithETH.selector);
    }

    function testRescueETH() public {
        _testRescueETH(tokenRescuer);
    }

    function testRescueETHNotOwner() public {
        _testRescueETHNotOwner(tokenRescuer);
    }

    function testRescueERC20() public {
        _testRescueERC20(tokenRescuer);
    }

    function testRescueERC20NotOwner() public {
        _testRescueERC20NotOwner(tokenRescuer);
    }

    function testBuyWithETHZeroOrders() public {
        ILooksRareAggregator.TradeData[] memory tradeData = new ILooksRareAggregator.TradeData[](0);
        vm.expectRevert(ILooksRareAggregator.InvalidOrderLength.selector);
        aggregator.buyWithETH(tradeData, false);
    }
}
