// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {OwnableTwoSteps} from "@looksrare/contracts-libs/contracts/OwnableTwoSteps.sol";
import {LooksRareProxy} from "../../contracts/proxies/LooksRareProxy.sol";
import {TokenRescuer} from "../../contracts/TokenRescuer.sol";
import {IProxy} from "../../contracts/interfaces/IProxy.sol";
import {BasicOrder, FeeData} from "../../contracts/libraries/OrderStructs.sol";
import {CollectionType} from "../../contracts/libraries/OrderEnums.sol";
import {TestHelpers} from "./TestHelpers.sol";
import {TokenRescuerTest} from "./TokenRescuer.t.sol";
import {LooksRareProxyTestHelpers} from "./LooksRareProxyTestHelpers.sol";

abstract contract TestParameters {
    address internal constant _buyer = address(1);
    address internal constant _fakeAggregator = address(69420);
}

contract LooksRareProxyTest is TestParameters, TestHelpers, TokenRescuerTest, LooksRareProxyTestHelpers {
    LooksRareProxy looksRareProxy;
    TokenRescuer tokenRescuer;

    function setUp() public {
        looksRareProxy = new LooksRareProxy(LOOKSRARE_V1, _fakeAggregator);
        tokenRescuer = TokenRescuer(address(looksRareProxy));
        vm.deal(_buyer, 200 ether);
    }

    function testExecuteZeroOrders() public asPrankedUser(_buyer) {
        BasicOrder[] memory orders = new BasicOrder[](0);
        bytes[] memory ordersExtraData = new bytes[](0);

        vm.etch(address(_fakeAggregator), address(looksRareProxy).code);
        vm.expectRevert(IProxy.InvalidOrderLength.selector);
        IProxy(_fakeAggregator).execute(orders, ordersExtraData, "", _buyer, false, 0, address(0));
    }

    function testExecuteOrdersLengthMismatch() public asPrankedUser(_buyer) {
        BasicOrder[] memory orders = validBAYCOrders();

        bytes[] memory ordersExtraData = new bytes[](1);
        ordersExtraData[0] = abi.encode(orders[0].price, 9550, 0, LOOKSRARE_STRATEGY_FIXED_PRICE);

        vm.etch(address(_fakeAggregator), address(looksRareProxy).code);
        vm.expectRevert(IProxy.InvalidOrderLength.selector);
        IProxy(_fakeAggregator).execute{value: orders[0].price + orders[1].price}(
            orders,
            ordersExtraData,
            "",
            _buyer,
            false,
            0,
            address(0)
        );
    }

    function testRescueETH() public {
        _testRescueETH(tokenRescuer);
    }

    function testRescueETHNotOwner() public {
        _testRescueETHNotOwner(tokenRescuer);
    }

    function testRescueETHInsufficientAmount() public {
        _testRescueETHInsufficientAmount(tokenRescuer);
    }

    function testRescueERC20() public {
        _testRescueERC20(tokenRescuer);
    }

    function testRescueERC20NotOwner() public {
        _testRescueERC20NotOwner(tokenRescuer);
    }

    function testRescueERC20InsufficientAmount() public {
        _testRescueERC20InsufficientAmount(tokenRescuer);
    }
}
