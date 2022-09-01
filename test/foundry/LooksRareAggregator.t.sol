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
    address internal constant _buyer = address(2);
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
        assertTrue(!aggregator.supportsProxyFunction(address(looksRareProxy), LooksRareProxy.execute.selector));
        vm.expectEmit(true, true, false, true);
        emit FunctionAdded(address(looksRareProxy), LooksRareProxy.execute.selector);
        aggregator.addFunction(address(looksRareProxy), LooksRareProxy.execute.selector);
        assertTrue(aggregator.supportsProxyFunction(address(looksRareProxy), LooksRareProxy.execute.selector));
    }

    function testAddFunctionNotOwner() public {
        vm.prank(_notOwner);
        vm.expectRevert(OwnableTwoSteps.NotOwner.selector);
        aggregator.addFunction(address(looksRareProxy), LooksRareProxy.execute.selector);
    }

    function testRemoveFunction() public {
        assertTrue(!aggregator.supportsProxyFunction(address(looksRareProxy), LooksRareProxy.execute.selector));
        aggregator.addFunction(address(looksRareProxy), LooksRareProxy.execute.selector);
        assertTrue(aggregator.supportsProxyFunction(address(looksRareProxy), LooksRareProxy.execute.selector));

        vm.expectEmit(true, true, false, true);
        emit FunctionRemoved(address(looksRareProxy), LooksRareProxy.execute.selector);
        aggregator.removeFunction(address(looksRareProxy), LooksRareProxy.execute.selector);
        assertTrue(!aggregator.supportsProxyFunction(address(looksRareProxy), LooksRareProxy.execute.selector));
    }

    function testRemoveFunctionNotOwner() public {
        aggregator.addFunction(address(looksRareProxy), LooksRareProxy.execute.selector);

        vm.prank(_notOwner);
        vm.expectRevert(OwnableTwoSteps.NotOwner.selector);
        aggregator.removeFunction(address(looksRareProxy), LooksRareProxy.execute.selector);
    }

    function testSetSupportsERC20Orders() public {
        assertTrue(!aggregator.supportsERC20Orders(address(looksRareProxy)));
        vm.expectEmit(true, true, false, true);
        emit SupportsERC20OrdersUpdated(address(looksRareProxy), true);
        aggregator.setSupportsERC20Orders(address(looksRareProxy), true);
        assertTrue(aggregator.supportsERC20Orders(address(looksRareProxy)));

        vm.expectEmit(true, true, false, true);
        emit SupportsERC20OrdersUpdated(address(looksRareProxy), false);
        aggregator.setSupportsERC20Orders(address(looksRareProxy), false);
        assertTrue(!aggregator.supportsERC20Orders(address(looksRareProxy)));
    }

    function testSetSupportsERC20OrdersNotOwner() public asPrankedUser(_notOwner) {
        vm.expectRevert(OwnableTwoSteps.NotOwner.selector);
        aggregator.setSupportsERC20Orders(address(looksRareProxy), true);
    }

    function testPullERC20Tokens() public {
        uint256 pullAmount = 69420e18;
        MockERC20 erc20 = new MockERC20();
        erc20.mint(_buyer, pullAmount);

        vm.prank(_buyer);
        erc20.approve(address(aggregator), 69420e18);

        aggregator.setSupportsERC20Orders(address(looksRareProxy), true);

        assertEq(erc20.balanceOf(address(looksRareProxy)), 0);

        vm.prank(address(looksRareProxy));
        aggregator.pullERC20Tokens(_buyer, address(erc20), pullAmount);

        assertEq(erc20.balanceOf(_buyer), 0);
        assertEq(erc20.balanceOf(address(looksRareProxy)), pullAmount);
        assertEq(erc20.allowance(_buyer, address(aggregator)), 0);
    }

    function testPullERC20TokensUnauthorized() public {
        uint256 pullAmount = 69420e18;
        MockERC20 erc20 = new MockERC20();
        erc20.mint(_buyer, pullAmount);

        vm.prank(_buyer);
        erc20.approve(address(aggregator), 69420e18);

        assertEq(erc20.balanceOf(address(looksRareProxy)), 0);

        vm.prank(address(looksRareProxy));
        vm.expectRevert(ILooksRareAggregator.UnauthorizedToPullTokens.selector);
        aggregator.pullERC20Tokens(_buyer, address(erc20), pullAmount);
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
        aggregator.execute(tradeData, _buyer, false);
    }
}
