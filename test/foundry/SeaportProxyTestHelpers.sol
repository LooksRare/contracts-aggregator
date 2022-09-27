// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {SeaportProxy} from "../../contracts/proxies/SeaportProxy.sol";
import {BasicOrder} from "../../contracts/libraries/OrderStructs.sol";
import {CollectionType} from "../../contracts/libraries/OrderEnums.sol";
import {AdditionalRecipient, FulfillmentComponent} from "../../contracts/libraries/seaport/ConsiderationStructs.sol";
import {OrderType} from "../../contracts/libraries/seaport/ConsiderationEnums.sol";

abstract contract SeaportProxyTestHelpers {
    address private constant BAYC = 0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D;

    function validBAYCId4560Order() internal pure returns (BasicOrder memory order) {
        order.signer = 0xA27503E089EF0e37D6eaF28aA444c46eB9FD9E40;
        order.collection = BAYC;
        order.collectionType = CollectionType.ERC721;

        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 4560;
        order.tokenIds = tokenIds;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1;
        order.amounts = amounts;

        order.price = 73 ether;
        order.currency = address(0);
        order.startTime = 1662729290;
        order.endTime = 1664697571;
        order
            .signature = hex"9f4a7f1eb8070e675987bff93aba879e469de1fe4a05294c6456bc7afa99b45d622a06b9a7f8fc5fef63cdbdfb837e88806e964a6d93406291eb05906af26c681b";
    }

    function validBAYCId9477Order() internal pure returns (BasicOrder memory order) {
        order.signer = 0x2ce485fe158593B9f3D4b840f1e44E3b77c96741;
        order.collection = BAYC;
        order.collectionType = CollectionType.ERC721;

        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 9477;
        order.tokenIds = tokenIds;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1;
        order.amounts = amounts;

        order.price = 84 ether;
        order.currency = address(0);
        order.startTime = 1662563436;
        order.endTime = 1665091508;
        order
            .signature = hex"b2616381d5c9b1569f88661a35b1899a6cbd1e4bdb4110c138073b3045d372c029b12f1ef561fd4d9bc8a5932348ad834ded1fd17668ae59fa5e0d4211bac1951c";
    }

    function validBAYCId2518Order() internal pure returns (BasicOrder memory order) {
        order.signer = 0x7a277Cf6E2F3704425195caAe4148848c29Ff815;
        order.collection = BAYC;
        order.collectionType = CollectionType.ERC721;

        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 2518;
        order.tokenIds = tokenIds;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1;
        order.amounts = amounts;

        order.price = 84 ether;
        order.currency = address(0);
        order.startTime = 1659797236;
        order.endTime = 1662475636;
        order
            .signature = hex"27deb8f1923b96693d8d5e1bf9304207e31b9cb49e588e8df5b3926b7547ba444afafe429fb2a17b4b97544d8383f3ad886fc15cab5a91382a56f9d65bb3dc231c";
    }

    function validBAYCId8498Order() internal pure returns (BasicOrder memory order) {
        order.signer = 0x72F1C8601C30C6f42CA8b0E85D1b2F87626A0deb;
        order.collection = BAYC;
        order.collectionType = CollectionType.ERC721;

        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 8498;
        order.tokenIds = tokenIds;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1;
        order.amounts = amounts;

        order.price = 84.78 ether;
        order.currency = address(0);
        order.startTime = 1659944298;
        order.endTime = 1662303030;
        order
            .signature = hex"fcdc82cba99c19522af3692070e4649ff573d20f2550eb29f7a24b3c39da74bd6a6c5b8444a2139c529301a8da011af414342d304609f896580e12fbd94d387a1b";
    }

    function validBAYCId4560OrderExtraData() internal pure returns (bytes memory) {
        AdditionalRecipient[] memory recipients = new AdditionalRecipient[](3);
        recipients[0].recipient = payable(0xA27503E089EF0e37D6eaF28aA444c46eB9FD9E40);
        recipients[0].amount = 69.35 ether;
        recipients[1].recipient = payable(0x0000a26b00c1F0DF003000390027140000fAa719);
        recipients[1].amount = 1.825 ether;
        recipients[2].recipient = payable(0xA858DDc0445d8131daC4d1DE01f834ffcbA52Ef1);
        recipients[2].amount = 1.825 ether;

        SeaportProxy.OrderExtraData memory orderExtraData;
        orderExtraData.numerator = 1;
        orderExtraData.denominator = 1;
        orderExtraData.orderType = OrderType.FULL_RESTRICTED;
        orderExtraData.zone = 0x004C00500000aD104D7DBd00e3ae0A5C00560C00;
        orderExtraData.zoneHash = bytes32(0);
        orderExtraData.salt = 84716561889548186;
        orderExtraData.conduitKey = 0x0000007b02230091a7ed01230072f7006a004d60a8d4e71d599b8104250f0000;
        orderExtraData.recipients = recipients;

        return abi.encode(orderExtraData);
    }

    function validBAYCId9477OrderExtraData() internal pure returns (bytes memory) {
        AdditionalRecipient[] memory recipients = new AdditionalRecipient[](3);
        recipients[0].recipient = payable(0x2ce485fe158593B9f3D4b840f1e44E3b77c96741);
        recipients[0].amount = 70.585 ether;
        recipients[1].recipient = payable(0x0000a26b00c1F0DF003000390027140000fAa719);
        recipients[1].amount = 1.8575 ether;
        recipients[2].recipient = payable(0xA858DDc0445d8131daC4d1DE01f834ffcbA52Ef1);
        recipients[2].amount = 1.8575 ether;

        SeaportProxy.OrderExtraData memory orderExtraData;
        orderExtraData.numerator = 1;
        orderExtraData.denominator = 1;
        orderExtraData.orderType = OrderType.FULL_RESTRICTED;
        orderExtraData.zone = 0x004C00500000aD104D7DBd00e3ae0A5C00560C00;
        orderExtraData.zoneHash = bytes32(0);
        orderExtraData.salt = 97387095972374677;
        orderExtraData.conduitKey = 0x0000007b02230091a7ed01230072f7006a004d60a8d4e71d599b8104250f0000;
        orderExtraData.recipients = recipients;

        return abi.encode(orderExtraData);
    }

    function validBAYCId2518OrderExtraData() internal pure returns (bytes memory) {
        AdditionalRecipient[] memory recipients = new AdditionalRecipient[](3);
        recipients[0].recipient = payable(0x7a277Cf6E2F3704425195caAe4148848c29Ff815);
        recipients[0].amount = 79.8 ether;
        recipients[1].recipient = payable(0x8De9C5A032463C561423387a9648c5C7BCC5BC90);
        recipients[1].amount = 2.1 ether;
        recipients[2].recipient = payable(0xA858DDc0445d8131daC4d1DE01f834ffcbA52Ef1);
        recipients[2].amount = 2.1 ether;

        SeaportProxy.OrderExtraData memory orderExtraData;
        orderExtraData.numerator = 1;
        orderExtraData.denominator = 1;
        orderExtraData.orderType = OrderType.FULL_RESTRICTED;
        orderExtraData.zone = 0x004C00500000aD104D7DBd00e3ae0A5C00560C00;
        orderExtraData.zoneHash = bytes32(0);
        orderExtraData.salt = 70769720963177607;
        orderExtraData.conduitKey = 0x0000007b02230091a7ed01230072f7006a004d60a8d4e71d599b8104250f0000;
        orderExtraData.recipients = recipients;

        return abi.encode(orderExtraData);
    }

    function validBAYCId8498OrderExtraData() internal pure returns (bytes memory) {
        AdditionalRecipient[] memory recipients = new AdditionalRecipient[](3);
        recipients[0].recipient = payable(0x72F1C8601C30C6f42CA8b0E85D1b2F87626A0deb);
        recipients[0].amount = 80.541 ether;
        recipients[1].recipient = payable(0x8De9C5A032463C561423387a9648c5C7BCC5BC90);
        recipients[1].amount = 2.1195 ether;
        recipients[2].recipient = payable(0xA858DDc0445d8131daC4d1DE01f834ffcbA52Ef1);
        recipients[2].amount = 2.1195 ether;

        SeaportProxy.OrderExtraData memory orderExtraData;
        orderExtraData.numerator = 1;
        orderExtraData.denominator = 1;
        orderExtraData.orderType = OrderType.FULL_RESTRICTED;
        orderExtraData.zone = 0x004C00500000aD104D7DBd00e3ae0A5C00560C00;
        orderExtraData.zoneHash = bytes32(0);
        orderExtraData.salt = 90974057687252886;
        orderExtraData.conduitKey = 0x0000007b02230091a7ed01230072f7006a004d60a8d4e71d599b8104250f0000;
        orderExtraData.recipients = recipients;

        return abi.encode(orderExtraData);
    }

    function validSingleBAYCExtraData() internal pure returns (bytes memory) {
        SeaportProxy.ExtraData memory extraData;

        extraData.offerFulfillments = new FulfillmentComponent[][](1);

        extraData.offerFulfillments[0] = new FulfillmentComponent[](1);
        extraData.offerFulfillments[0][0].orderIndex = 0;
        extraData.offerFulfillments[0][0].itemIndex = 0;

        extraData.considerationFulfillments = new FulfillmentComponent[][](3);

        extraData.considerationFulfillments[0] = new FulfillmentComponent[](1);
        extraData.considerationFulfillments[0][0].orderIndex = 0;
        extraData.considerationFulfillments[0][0].itemIndex = 0;

        extraData.considerationFulfillments[1] = new FulfillmentComponent[](1);
        extraData.considerationFulfillments[1][0].orderIndex = 0;
        extraData.considerationFulfillments[1][0].itemIndex = 1;

        extraData.considerationFulfillments[2] = new FulfillmentComponent[](1);
        extraData.considerationFulfillments[2][0].orderIndex = 0;
        extraData.considerationFulfillments[2][0].itemIndex = 2;

        return abi.encode(extraData);
    }

    function validMultipleOfferFulfillments()
        internal
        pure
        returns (FulfillmentComponent[][] memory offerFulfillments)
    {
        offerFulfillments = new FulfillmentComponent[][](2);

        offerFulfillments[0] = new FulfillmentComponent[](1);
        offerFulfillments[0][0].orderIndex = 0;
        offerFulfillments[0][0].itemIndex = 0;

        offerFulfillments[1] = new FulfillmentComponent[](1);
        offerFulfillments[1][0].orderIndex = 1;
        offerFulfillments[1][0].itemIndex = 0;
    }

    function validMultipleConsiderationFulfillments()
        internal
        pure
        returns (FulfillmentComponent[][] memory considerationFulfillments)
    {
        considerationFulfillments = new FulfillmentComponent[][](4);

        considerationFulfillments[0] = new FulfillmentComponent[](1);
        considerationFulfillments[0][0].orderIndex = 0;
        considerationFulfillments[0][0].itemIndex = 0;

        considerationFulfillments[1] = new FulfillmentComponent[](1);
        considerationFulfillments[1][0].orderIndex = 1;
        considerationFulfillments[1][0].itemIndex = 0;

        considerationFulfillments[2] = new FulfillmentComponent[](2);
        considerationFulfillments[2][0].orderIndex = 0;
        considerationFulfillments[2][0].itemIndex = 1;
        considerationFulfillments[2][1].orderIndex = 1;
        considerationFulfillments[2][1].itemIndex = 1;

        considerationFulfillments[3] = new FulfillmentComponent[](2);
        considerationFulfillments[3][0].orderIndex = 0;
        considerationFulfillments[3][0].itemIndex = 2;
        considerationFulfillments[3][1].orderIndex = 1;
        considerationFulfillments[3][1].itemIndex = 2;
    }

    function validMultipleBAYCExtraData() internal pure returns (bytes memory) {
        SeaportProxy.ExtraData memory extraData;

        extraData.offerFulfillments = validMultipleOfferFulfillments();
        extraData.considerationFulfillments = validMultipleConsiderationFulfillments();

        return abi.encode(extraData);
    }
}
