// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import {LooksRareAggregator} from "../../contracts/LooksRareAggregator.sol";
import {ERC20EnabledLooksRareAggregator} from "../../contracts/ERC20EnabledLooksRareAggregator.sol";
import {LooksRareProxy} from "../../contracts/proxies/LooksRareProxy.sol";
import {TokenRescuer} from "../../contracts/TokenRescuer.sol";
import {ILooksRareAggregator} from "../../contracts/interfaces/ILooksRareAggregator.sol";
import {BasicOrder, TokenTransfer} from "../../contracts/libraries/OrderStructs.sol";
import {IOwnableTwoSteps} from "@looksrare/contracts-libs/contracts/interfaces/IOwnableTwoSteps.sol";
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

    function execute(
        TokenTransfer[] calldata,
        TradeData[] calldata,
        address,
        address,
        bool
    ) external payable {
        revert("This contract inherits from ILooksRareAggregator so execute has to be defined");
    }

    function setUp() public {
        aggregator = new LooksRareAggregator();
        tokenRescuer = TokenRescuer(address(aggregator));
        looksRareProxy = new LooksRareProxy(LOOKSRARE_V1, address(aggregator));
    }

    function testSetERC20EnabledLooksRareAggregator() public {
        assertEq(address(aggregator.erc20EnabledLooksRareAggregator()), address(0));
        vm.expectEmit(true, false, false, false);
        emit ERC20EnabledLooksRareAggregatorSet();
        address erc20EnabledLooksRareAggregator = address(new ERC20EnabledLooksRareAggregator(address(aggregator)));
        aggregator.setERC20EnabledLooksRareAggregator(erc20EnabledLooksRareAggregator);
        assertEq(address(aggregator.erc20EnabledLooksRareAggregator()), erc20EnabledLooksRareAggregator);
    }

    function testSetERC20EnabledLooksRareAggregatorAlreadySet() public {
        address erc20EnabledLooksRareAggregator = address(new ERC20EnabledLooksRareAggregator(address(aggregator)));
        aggregator.setERC20EnabledLooksRareAggregator(erc20EnabledLooksRareAggregator);
        assertEq(address(aggregator.erc20EnabledLooksRareAggregator()), erc20EnabledLooksRareAggregator);

        vm.expectRevert(ILooksRareAggregator.AlreadySet.selector);
        aggregator.setERC20EnabledLooksRareAggregator(erc20EnabledLooksRareAggregator);
    }

    function testSetERC20EnabledLooksRareAggregatorNotOwner() public {
        address erc20EnabledLooksRareAggregator = address(new ERC20EnabledLooksRareAggregator(address(aggregator)));
        vm.prank(_notOwner);
        vm.expectRevert(IOwnableTwoSteps.NotOwner.selector);
        aggregator.setERC20EnabledLooksRareAggregator(erc20EnabledLooksRareAggregator);
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
        vm.expectRevert(IOwnableTwoSteps.NotOwner.selector);
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
        vm.expectRevert(IOwnableTwoSteps.NotOwner.selector);
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
        vm.expectRevert(IOwnableTwoSteps.NotOwner.selector);
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
        vm.expectRevert(IOwnableTwoSteps.NotOwner.selector);
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
        aggregator.execute(tokenTransfers, tradeData, _buyer, _buyer, false);
    }

    function testBuyWithETHZeroOriginator() public {
        TokenTransfer[] memory tokenTransfers = new TokenTransfer[](0);
        ILooksRareAggregator.TradeData[] memory tradeData = new ILooksRareAggregator.TradeData[](1);
        vm.expectRevert(ILooksRareAggregator.ZeroAddress.selector);
        aggregator.execute(tokenTransfers, tradeData, address(0), _buyer, false);
    }

    function testBuyWithETHZeroRecipient() public {
        TokenTransfer[] memory tokenTransfers = new TokenTransfer[](0);
        ILooksRareAggregator.TradeData[] memory tradeData = new ILooksRareAggregator.TradeData[](1);
        vm.expectRevert(ILooksRareAggregator.ZeroAddress.selector);
        aggregator.execute(tokenTransfers, tradeData, _buyer, address(0), false);
    }

    function testBuyWithERC20ButMsgSenderIsNotERC20EnabledLooksRareAggregator() public {
        MockERC20 erc20 = new MockERC20();
        TokenTransfer[] memory tokenTransfers = new TokenTransfer[](1);
        tokenTransfers[0].amount = 1 ether;
        tokenTransfers[0].currency = address(erc20);

        ILooksRareAggregator.TradeData[] memory tradeData = new ILooksRareAggregator.TradeData[](1);

        vm.expectRevert(ILooksRareAggregator.UseERC20EnabledLooksRareAggregator.selector);
        aggregator.execute(tokenTransfers, tradeData, _buyer, _buyer, false);
    }
}
