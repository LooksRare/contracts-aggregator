// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import {OwnableTwoSteps} from "@looksrare/contracts-libs/contracts/OwnableTwoSteps.sol";
import {SeaportProxy} from "../../contracts/proxies/SeaportProxy.sol";
import {OrderType} from "../../contracts/libraries/seaport/ConsiderationEnums.sol";
import {AdditionalRecipient, Fulfillment, FulfillmentComponent} from "../../contracts/libraries/seaport/ConsiderationStructs.sol";
import {IProxy} from "../../contracts/proxies/IProxy.sol";
import {BasicOrder} from "../../contracts/libraries/OrderStructs.sol";
import {CollectionType} from "../../contracts/libraries/OrderEnums.sol";
import {TestHelpers} from "./TestHelpers.sol";

abstract contract TestParameters {
    address internal constant SEAPORT = 0x00000000006c3852cbEf3e08E8dF289169EdE581;
    address internal constant BAYC = 0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D;
    address internal _buyer = address(1);
}

contract SeaportProxyTest is TestParameters, TestHelpers {
    SeaportProxy seaportProxy;

    function setUp() public {
        seaportProxy = new SeaportProxy(SEAPORT);
        vm.deal(_buyer, 100 ether);
    }

    function testBuyWithETHZeroOrders() public asPrankedUser(_buyer) {
        BasicOrder[] memory orders = new BasicOrder[](0);
        bytes[] memory ordersExtraData = new bytes[](0);

        vm.expectRevert(IProxy.InvalidOrderLength.selector);
        seaportProxy.buyWithETH(orders, ordersExtraData, validBAYCExtraData(), false);
    }

    function testBuyWithETHOrdersLengthMismatch() public asPrankedUser(_buyer) {
        BasicOrder[] memory orders = validBAYCOrder();

        bytes[] memory ordersExtraData = new bytes[](2);
        ordersExtraData[0] = validBAYCOrderExtraData();
        ordersExtraData[1] = validBAYCOrderExtraData();

        vm.expectRevert(IProxy.InvalidOrderLength.selector);
        seaportProxy.buyWithETH{value: orders[0].price}(orders, ordersExtraData, validBAYCExtraData(), false);
    }

    function testBuyWithETHOrdersRecipientZeroAddress() public {
        BasicOrder[] memory orders = validBAYCOrder();
        orders[0].recipient = address(0);

        bytes[] memory ordersExtraData = new bytes[](1);
        ordersExtraData[0] = validBAYCOrderExtraData();

        vm.expectRevert(IProxy.ZeroAddress.selector);
        seaportProxy.buyWithETH{value: orders[0].price}(orders, ordersExtraData, validBAYCExtraData(), false);
    }

    function validBAYCOrder() private returns (BasicOrder[] memory orders) {
        orders = new BasicOrder[](1);
        orders[0].signer = 0x7a277Cf6E2F3704425195caAe4148848c29Ff815;
        orders[0].recipient = payable(_buyer);
        orders[0].collection = BAYC;
        orders[0].collectionType = CollectionType.ERC721;

        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 2518;
        orders[0].tokenIds = tokenIds;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1;
        orders[0].amounts = amounts;

        orders[0].price = 84 ether;
        orders[0].currency = address(0);
        orders[0].startTime = 1659797236;
        orders[0].endTime = 1662475636;
        orders[0]
            .signature = "0x27deb8f1923b96693d8d5e1bf9304207e31b9cb49e588e8df5b3926b7547ba444afafe429fb2a17b4b97544d8383f3ad886fc15cab5a91382a56f9d65bb3dc231c";
    }

    function validBAYCOrderExtraData() private returns (bytes memory orderExtraData) {
        AdditionalRecipient[] memory recipients = new AdditionalRecipient[](3);
        recipients[0].recipient = payable(0x7a277Cf6E2F3704425195caAe4148848c29Ff815);
        recipients[0].amount = 79.8 ether;
        recipients[1].recipient = payable(0x8De9C5A032463C561423387a9648c5C7BCC5BC90);
        recipients[1].amount = 2.1 ether;
        recipients[2].recipient = payable(0xA858DDc0445d8131daC4d1DE01f834ffcbA52Ef1);
        recipients[2].amount = 2.1 ether;

        orderExtraData = abi.encode(
            OrderType.FULL_RESTRICTED,
            0x004C00500000aD104D7DBd00e3ae0A5C00560C00,
            0x0000000000000000000000000000000000000000000000000000000000000000,
            70769720963177607,
            0x0000007b02230091a7ed01230072f7006a004d60a8d4e71d599b8104250f0000,
            recipients
        );
    }

    function validBAYCExtraData() private returns (bytes memory extraData) {
        Fulfillment memory fulfillment;

        fulfillment.offerComponents = new FulfillmentComponent[](1);
        fulfillment.offerComponents[0].orderIndex = 0;
        fulfillment.offerComponents[0].itemIndex = 0;

        fulfillment.considerationComponents = new FulfillmentComponent[](1);
        fulfillment.considerationComponents[0].orderIndex = 0;
        fulfillment.considerationComponents[0].itemIndex = 0;

        extraData = abi.encode(fulfillment);
    }
}
