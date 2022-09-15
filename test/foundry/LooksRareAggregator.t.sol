// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import {LooksRareAggregator} from "../../contracts/LooksRareAggregator.sol";
import {LooksRareProxy} from "../../contracts/proxies/LooksRareProxy.sol";
import {TokenLogic} from "../../contracts/TokenLogic.sol";
import {ILooksRareAggregator} from "../../contracts/interfaces/ILooksRareAggregator.sol";
import {BasicOrder, TokenTransfer} from "../../contracts/libraries/OrderStructs.sol";
import {OwnableTwoSteps} from "@looksrare/contracts-libs/contracts/OwnableTwoSteps.sol";
import {MockERC20} from "./utils/MockERC20.sol";
import {TestHelpers} from "./TestHelpers.sol";
import {TokenLogicTest} from "./TokenLogic.t.sol";

abstract contract TestParameters {
    address internal constant LOOKSRARE_V1 = 0x59728544B08AB483533076417FbBB2fD0B17CE3a;
    address internal constant _notOwner = address(1);
    address internal constant _buyer = address(2);
}

contract LooksRareAggregatorTest is TestParameters, TestHelpers, TokenLogicTest, ILooksRareAggregator {
    LooksRareAggregator aggregator;
    LooksRareProxy looksRareProxy;
    TokenLogic tokenRescuer;

    function setUp() public {
        aggregator = new LooksRareAggregator();
        tokenRescuer = TokenLogic(address(aggregator));
        looksRareProxy = new LooksRareProxy(LOOKSRARE_V1, address(aggregator));
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

    function testApprove() public {
        MockERC20 erc20 = new MockERC20();
        assertEq(erc20.allowance(address(aggregator), address(looksRareProxy)), 0);
        aggregator.approve(address(looksRareProxy), address(erc20));
        assertEq(erc20.allowance(address(aggregator), address(looksRareProxy)), type(uint256).max);
    }

    function testApproveNotOwner() public {
        MockERC20 erc20 = new MockERC20();
        vm.prank(_buyer);
        vm.expectRevert(OwnableTwoSteps.NotOwner.selector);
        aggregator.approve(address(erc20), address(looksRareProxy));
    }

    function testRevoke() public {
        MockERC20 erc20 = new MockERC20();

        aggregator.approve(address(looksRareProxy), address(erc20));
        assertEq(erc20.allowance(address(aggregator), address(looksRareProxy)), type(uint256).max);

        aggregator.revoke(address(looksRareProxy), address(erc20));
        assertEq(erc20.allowance(address(aggregator), address(looksRareProxy)), 0);
    }

    function testRevokeNotOwner() public {
        MockERC20 erc20 = new MockERC20();
        vm.prank(_buyer);
        vm.expectRevert(OwnableTwoSteps.NotOwner.selector);
        aggregator.revoke(address(looksRareProxy), address(erc20));
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
        TokenTransfer[] memory tokenTransfers = new TokenTransfer[](0);
        ILooksRareAggregator.TradeData[] memory tradeData = new ILooksRareAggregator.TradeData[](0);
        vm.expectRevert(ILooksRareAggregator.InvalidOrderLength.selector);
        aggregator.execute(tokenTransfers, tradeData, _buyer, false);
    }
}
