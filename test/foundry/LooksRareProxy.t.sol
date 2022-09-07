// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import {OwnableTwoSteps} from "@looksrare/contracts-libs/contracts/OwnableTwoSteps.sol";
import {LooksRareProxy} from "../../contracts/proxies/LooksRareProxy.sol";
import {TokenLogic} from "../../contracts/TokenLogic.sol";
import {IProxy} from "../../contracts/proxies/IProxy.sol";
import {BasicOrder, TokenTransfer} from "../../contracts/libraries/OrderStructs.sol";
import {CollectionType} from "../../contracts/libraries/OrderEnums.sol";
import {TestHelpers} from "./TestHelpers.sol";
import {TokenLogicTest} from "./TokenLogic.t.sol";
import {LooksRareProxyTestHelpers} from "./LooksRareProxyTestHelpers.sol";

abstract contract TestParameters {
    address internal constant LOOKSRARE_V1 = 0x59728544B08AB483533076417FbBB2fD0B17CE3a;
    address internal constant LOOKSRARE_STRATEGY_FIXED_PRICE = 0x56244Bb70CbD3EA9Dc8007399F61dFC065190031;
    address internal constant _buyer = address(1);
}

contract LooksRareProxyTest is TestParameters, TestHelpers, TokenLogicTest, LooksRareProxyTestHelpers {
    LooksRareProxy looksRareProxy;
    TokenLogic tokenRescuer;

    function setUp() public {
        looksRareProxy = new LooksRareProxy(LOOKSRARE_V1);
        tokenRescuer = TokenLogic(address(looksRareProxy));
        vm.deal(_buyer, 200 ether);
    }

    function testBuyWithETHZeroOrders() public asPrankedUser(_buyer) {
        TokenTransfer[] memory tokenTransfers = new TokenTransfer[](0);
        BasicOrder[] memory orders = new BasicOrder[](0);
        bytes[] memory ordersExtraData = new bytes[](0);

        vm.expectRevert(IProxy.InvalidOrderLength.selector);
        looksRareProxy.execute(tokenTransfers, orders, ordersExtraData, "", _buyer, false);
    }

    function testBuyWithETHOrdersLengthMismatch() public asPrankedUser(_buyer) {
        TokenTransfer[] memory tokenTransfers = new TokenTransfer[](0);
        BasicOrder[] memory orders = validBAYCOrders();

        bytes[] memory ordersExtraData = new bytes[](1);
        ordersExtraData[0] = abi.encode(orders[0].price, 9550, 0, LOOKSRARE_STRATEGY_FIXED_PRICE);

        vm.expectRevert(IProxy.InvalidOrderLength.selector);
        looksRareProxy.execute{value: orders[0].price + orders[1].price}(
            tokenTransfers,
            orders,
            ordersExtraData,
            "",
            _buyer,
            false
        );
    }

    function testBuyWithETHOrdersRecipientZeroAddress() public {
        TokenTransfer[] memory tokenTransfers = new TokenTransfer[](0);
        BasicOrder[] memory orders = validBAYCOrders();

        bytes[] memory ordersExtraData = new bytes[](2);
        ordersExtraData[0] = abi.encode(orders[0].price, 9550, 0, LOOKSRARE_STRATEGY_FIXED_PRICE);
        ordersExtraData[0] = abi.encode(orders[1].price, 8500, 0, LOOKSRARE_STRATEGY_FIXED_PRICE);

        vm.expectRevert(IProxy.ZeroAddress.selector);
        looksRareProxy.execute{value: orders[0].price + orders[1].price}(
            tokenTransfers,
            orders,
            ordersExtraData,
            "",
            address(0),
            false
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
