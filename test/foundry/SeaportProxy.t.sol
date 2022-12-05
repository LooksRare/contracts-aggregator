// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {OwnableTwoSteps} from "@looksrare/contracts-libs/contracts/OwnableTwoSteps.sol";
import {SeaportProxy} from "../../contracts/proxies/SeaportProxy.sol";
import {OrderType} from "../../contracts/libraries/seaport/ConsiderationEnums.sol";
import {AdditionalRecipient, Fulfillment, FulfillmentComponent} from "../../contracts/libraries/seaport/ConsiderationStructs.sol";
import {IProxy} from "../../contracts/interfaces/IProxy.sol";
import {BasicOrder} from "../../contracts/libraries/OrderStructs.sol";
import {CollectionType} from "../../contracts/libraries/OrderEnums.sol";
import {InvalidOrderLength} from "../../contracts/libraries/Errors.sol";
import {TestHelpers} from "./TestHelpers.sol";
import {TestParameters} from "./TestParameters.sol";
import {SeaportProxyTestHelpers} from "./SeaportProxyTestHelpers.sol";
import {MockERC20} from "./utils/MockERC20.sol";

/**
 * @notice SeaportProxy tests, tests involving actual executions live in other tests
 */
contract SeaportProxyTest is TestParameters, TestHelpers, SeaportProxyTestHelpers {
    SeaportProxy private seaportProxy;

    function setUp() public {
        seaportProxy = new SeaportProxy(SEAPORT, _fakeAggregator);
        vm.deal(_buyer, 100 ether);
    }

    function testExecuteZeroOrders() public asPrankedUser(_buyer) {
        BasicOrder[] memory orders = new BasicOrder[](0);
        bytes[] memory ordersExtraData = new bytes[](0);

        vm.etch(address(_fakeAggregator), address(seaportProxy).code);
        vm.expectRevert(InvalidOrderLength.selector);
        IProxy(_fakeAggregator).execute(orders, ordersExtraData, validSingleOfferExtraData(3), _buyer, false);
    }

    function testExecuteOrdersLengthMismatch() public asPrankedUser(_buyer) {
        BasicOrder memory order = validBAYCId2518Order();
        BasicOrder[] memory orders = new BasicOrder[](1);
        orders[0] = order;

        bytes[] memory ordersExtraData = new bytes[](2);
        ordersExtraData[0] = validBAYCId2518OrderExtraData();
        ordersExtraData[1] = validBAYCId8498OrderExtraData();

        vm.etch(address(_fakeAggregator), address(seaportProxy).code);
        vm.expectRevert(InvalidOrderLength.selector);
        IProxy(_fakeAggregator).execute{value: orders[0].price}(
            orders,
            ordersExtraData,
            validSingleOfferExtraData(3),
            _buyer,
            false
        );
    }
}
