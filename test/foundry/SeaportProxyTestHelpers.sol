// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {SeaportProxy} from "../../contracts/proxies/SeaportProxy.sol";
import {BasicOrder} from "../../contracts/libraries/OrderStructs.sol";
import {CollectionType} from "../../contracts/libraries/OrderEnums.sol";
import {AdditionalRecipient, FulfillmentComponent} from "../../contracts/libraries/seaport/ConsiderationStructs.sol";
import {OrderType} from "../../contracts/libraries/seaport/ConsiderationEnums.sol";

abstract contract SeaportProxyTestHelpers {
    address private constant BAYC = 0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D;
    address internal constant CITY_DAO = 0x7EeF591A6CC0403b9652E98E88476fe1bF31dDeb;
    address internal constant SEAPORT = 0x00000000006c3852cbEf3e08E8dF289169EdE581;
    address internal constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address internal constant OPENSEA_FEES_3 = 0x0000a26b00c1F0DF003000390027140000fAa719;
    address internal constant YUGA_LABS = 0xA858DDc0445d8131daC4d1DE01f834ffcbA52Ef1;

    function validCityDaoOrders() internal pure returns (BasicOrder[] memory orders) {
        orders = new BasicOrder[](2);

        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 42;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1;

        orders[0].price = 0.298 ether;
        orders[0].signer = 0xDaeBB886B2B0bB6bDc5413C82428f41c73fa7072;
        orders[0].collection = CITY_DAO;
        orders[0].collectionType = CollectionType.ERC1155;
        orders[0].tokenIds = tokenIds;
        orders[0].amounts = amounts;
        orders[0].currency = address(0);
        orders[0].startTime = 1660199991;
        orders[0].endTime = 1660804791;
        orders[0]
            .signature = hex"a7cf4d0b35737c8acca7a30cc6a8bbadc6538ae105b3b290a7857633b71ec00640204226926a3df9d0060aa23ba042a3527a3d8aef7e2c9f3f77548e32ede1df1c";

        orders[1].price = 0.399 ether;
        orders[1].signer = 0x0061331952BdbA147DCAe69976fd1cDEF26D3971;
        orders[1].collection = CITY_DAO;
        orders[1].collectionType = CollectionType.ERC1155;
        orders[1].tokenIds = tokenIds;
        orders[1].amounts = amounts;
        orders[1].currency = address(0);
        orders[1].startTime = 1660186260;
        orders[1].endTime = 1660791060;
        orders[1]
            .signature = hex"f997881f8c99d468b1d2c7fb073b04ed488c367b0002becf4ba4b745e4b332af79de492eb32bf0cf9572c6d6026c226175d5b16f3862c68197d42f41ad71a6b51b";
    }

    function validBAYCId9948Order() internal pure returns (BasicOrder memory order) {
        order.signer = 0xeCBA5f51925E6CCeC26dA38Dcd7D5305f6BdFbcb;
        order.collection = BAYC;
        order.collectionType = CollectionType.ERC721;

        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 9948;
        order.tokenIds = tokenIds;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1;
        order.amounts = amounts;

        order.price = 175000e6;
        order.currency = USDC;
        order.startTime = 1662523477;
        order.endTime = 1662854040;
        order
            .signature = hex"4bcfc890a5ef871c7070b116e6743f3cd9540f9e71f93a29c1c1e9f44d0b854f0e4a6f9ed05853cd37109f2869fbbeb8e13e3ea4330c92c6ea87b7b90e204ae01c";
    }

    function validBAYCId8350Order() internal pure returns (BasicOrder memory order) {
        order.signer = 0x1c66f8A8fa9D34D26b6767cca81E4f0fb8F0692f;
        order.collection = BAYC;
        order.collectionType = CollectionType.ERC721;

        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 8350;
        order.tokenIds = tokenIds;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1;
        order.amounts = amounts;

        order.price = 300000e6;
        order.currency = USDC;
        order.startTime = 1661708793;
        order.endTime = 1677264393;
        order
            .signature = hex"1eb8f9bcb487e55e1f9a7524e0cadb382583a4384dff6422f267de46da64d25c0d2ee97f32f6202d5cf69af8876c2e43b8c2d247e4386861c8a7e7845cddeb091b";
    }

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

    function validCityDaoOrdersExtraData() internal pure returns (bytes[] memory ordersExtraData) {
        ordersExtraData = new bytes[](2);
        // Bytes copied from TypeScript test
        ordersExtraData[
            0
        ] = hex"0000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000003000000000000000000000000004c00500000ad104d7dbd00e3ae0a5c00560c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a3cb8b9f5c9d180000007b02230091a7ed01230072f7006a004d60a8d4e71d599b8104250f000000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000003000000000000000000000000000000000000000000000000039e5ebe552ee000000000000000000000000000daebb886b2b0bb6bdc5413c82428f41c73fa7072000000000000000000000000000000000000000000000000001a77bc4b93a0000000000000000000000000008de9c5a032463c561423387a9648c5c7bcc5bc900000000000000000000000000000000000000000000000000069def12e4e800000000000000000000000000060e7343205c9c88788a22c40030d35f9370d302d";
        ordersExtraData[
            1
        ] = hex"0000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000003000000000000000000000000004c00500000ad104d7dbd00e3ae0a5c00560c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000054065f515c65880000007b02230091a7ed01230072f7006a004d60a8d4e71d599b8104250f00000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000300000000000000000000000000000000000000000000000004d85756773550000000000000000000000000000061331952bdba147dcae69976fd1cdef26d397100000000000000000000000000000000000000000000000000237035aba270000000000000000000000000008de9c5a032463c561423387a9648c5c7bcc5bc90000000000000000000000000000000000000000000000000008dc0d6ae89c00000000000000000000000000060e7343205c9c88788a22c40030d35f9370d302d";
    }

    function validBAYCId9948OrderExtraData() internal pure returns (bytes memory) {
        AdditionalRecipient[] memory recipients = new AdditionalRecipient[](3);
        recipients[0].recipient = payable(0xeCBA5f51925E6CCeC26dA38Dcd7D5305f6BdFbcb);
        recipients[0].amount = 166250e6;
        recipients[1].recipient = payable(OPENSEA_FEES_3);
        recipients[1].amount = 4375e6;
        recipients[2].recipient = payable(YUGA_LABS);
        recipients[2].amount = 4375e6;

        SeaportProxy.OrderExtraData memory orderExtraData;
        orderExtraData.numerator = 1;
        orderExtraData.denominator = 1;
        orderExtraData.orderType = OrderType.FULL_RESTRICTED;
        orderExtraData.zone = 0x004C00500000aD104D7DBd00e3ae0A5C00560C00;
        orderExtraData.zoneHash = bytes32(0);
        orderExtraData.salt = 38618698744363512;
        orderExtraData.conduitKey = 0x0000007b02230091a7ed01230072f7006a004d60a8d4e71d599b8104250f0000;
        orderExtraData.recipients = recipients;

        return abi.encode(orderExtraData);
    }

    function validBAYCId8350OrderExtraData() internal pure returns (bytes memory) {
        AdditionalRecipient[] memory recipients = new AdditionalRecipient[](3);
        recipients[0].recipient = payable(0x1c66f8A8fa9D34D26b6767cca81E4f0fb8F0692f);
        recipients[0].amount = 285000e6;
        recipients[1].recipient = payable(OPENSEA_FEES_3);
        recipients[1].amount = 7500e6;
        recipients[2].recipient = payable(YUGA_LABS);
        recipients[2].amount = 7500e6;

        SeaportProxy.OrderExtraData memory orderExtraData;
        orderExtraData.numerator = 1;
        orderExtraData.denominator = 1;
        orderExtraData.orderType = OrderType.FULL_RESTRICTED;
        orderExtraData.zone = 0x004C00500000aD104D7DBd00e3ae0A5C00560C00;
        orderExtraData.zoneHash = bytes32(0);
        orderExtraData.salt = 49088034629033451;
        orderExtraData.conduitKey = 0x0000007b02230091a7ed01230072f7006a004d60a8d4e71d599b8104250f0000;
        orderExtraData.recipients = recipients;

        return abi.encode(orderExtraData);
    }

    function validBAYCId4560OrderExtraData() internal pure returns (bytes memory) {
        AdditionalRecipient[] memory recipients = new AdditionalRecipient[](3);
        recipients[0].recipient = payable(0xA27503E089EF0e37D6eaF28aA444c46eB9FD9E40);
        recipients[0].amount = 69.35 ether;
        recipients[1].recipient = payable(OPENSEA_FEES_3);
        recipients[1].amount = 1.825 ether;
        recipients[2].recipient = payable(YUGA_LABS);
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
        recipients[1].recipient = payable(OPENSEA_FEES_3);
        recipients[1].amount = 1.8575 ether;
        recipients[2].recipient = payable(YUGA_LABS);
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
        recipients[2].recipient = payable(YUGA_LABS);
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
        recipients[2].recipient = payable(YUGA_LABS);
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
