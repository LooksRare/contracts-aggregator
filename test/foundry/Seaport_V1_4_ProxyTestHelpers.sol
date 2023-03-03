// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {SeaportProxy} from "../../contracts/proxies/SeaportProxy.sol";
import {BasicOrder} from "../../contracts/libraries/OrderStructs.sol";
import {CollectionType} from "../../contracts/libraries/OrderEnums.sol";
import {AdditionalRecipient, FulfillmentComponent} from "../../contracts/libraries/seaport/ConsiderationStructs.sol";
import {OrderType} from "../../contracts/libraries/seaport/ConsiderationEnums.sol";

/**
 * @notice Seaport orders helper contract
 */
abstract contract Seaport_V1_4_ProxyTestHelpers {
    address internal constant OFFERER = 0x7c741AD1dd7Ce77E88e7717De1cC20e3314b4F38;
    address internal constant FEES = 0x0000a26b00c1F0DF003000390027140000fAa719;
    address internal constant MULTIFAUCET_NFT = 0xf5de760f2e916647fd766B4AD9E85ff943cE3A2b;
    address internal constant SEAPORT = 0x00000000000001ad428e4906aE43D8F9852d0dD6;
    address private constant WETH_GOERLI = 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6;

    function validMultifaucetId2828266Order() internal pure returns (BasicOrder memory order) {
        order.signer = OFFERER;
        order.collection = MULTIFAUCET_NFT;
        order.collectionType = CollectionType.ERC721;

        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 2828266;
        order.tokenIds = tokenIds;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1;
        order.amounts = amounts;

        order.price = 4 ether;
        order.currency = WETH_GOERLI;
        order.startTime = 1677851098;
        order.endTime = 1680525898;
        order
            .signature = hex"3b225a5f375ebc4ed6aeded35373e2154332289b442a8b1e5559788aea61b1b9d24e7446affaeba7ea2c46e343b35b5d2008d36a9b912274d96fe336a1cacca6";
    }

    function validMultifaucetId2828267Order() internal pure returns (BasicOrder memory order) {
        order.signer = OFFERER;
        order.collection = MULTIFAUCET_NFT;
        order.collectionType = CollectionType.ERC721;

        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 2828267;
        order.tokenIds = tokenIds;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1;
        order.amounts = amounts;

        order.price = 3 ether;
        order.currency = WETH_GOERLI;
        order.startTime = 1677846317;
        order.endTime = 1680521117;
        order
            .signature = hex"2c41838edbb10aaf552d6b80082153f3e1dd580f806be4c3e29f42bd7d576223e9d4f1ea094b49ad162088dd6c2b1a13425572497322d1b03fccfc2e2abeb2b1";
    }

    function validMultifaucetId2828268Order() internal pure returns (BasicOrder memory order) {
        order.signer = OFFERER;
        order.collection = MULTIFAUCET_NFT;
        order.collectionType = CollectionType.ERC721;

        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 2828268;
        order.tokenIds = tokenIds;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1;
        order.amounts = amounts;

        order.price = 2 ether;
        order.currency = address(0);
        order.startTime = 1677843106;
        order.endTime = 1680517906;
        order
            .signature = hex"788cc332bec33bdf52e3506ef727a6e33c1ef583d6ee8323cabd4c055f4a3bbef6fb259264fdae65fbc00c80292e85b60d51c8dd6a496d448ad224b12a4aebd1";
    }

    function validMultifaucetId2828270Order() internal pure returns (BasicOrder memory order) {
        order.signer = OFFERER;
        order.collection = MULTIFAUCET_NFT;
        order.collectionType = CollectionType.ERC721;

        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 2828270;
        order.tokenIds = tokenIds;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1;
        order.amounts = amounts;

        order.price = 1 ether;
        order.currency = address(0);
        order.startTime = 1677842451;
        order.endTime = 1680517251;
        order
            .signature = hex"e73cfc9d62d01cc4b7ff5aa31e0632b5ccd8ff2dd010d31a1464306bd0b5a6bd6494e202edb2f16e085e0aa0573afa5213180453a4c312edad97e11f39826671";
    }

    function validMultifaucetId2828266OrderExtraData() internal pure returns (bytes memory) {
        AdditionalRecipient[] memory recipients = new AdditionalRecipient[](2);
        recipients[0].recipient = payable(OFFERER);
        recipients[0].amount = 3980000000000000000;
        recipients[1].recipient = payable(FEES);
        recipients[1].amount = 20000000000000000;

        SeaportProxy.OrderExtraData memory orderExtraData = _baseOrderExtraData();
        orderExtraData.salt = 0x360c6ebe000000000000000000000000000000000000000077d23ecfb2815436;
        orderExtraData.recipients = recipients;

        return abi.encode(orderExtraData);
    }

    function validMultifaucetId2828267OrderExtraData() internal pure returns (bytes memory) {
        AdditionalRecipient[] memory recipients = new AdditionalRecipient[](2);
        recipients[0].recipient = payable(OFFERER);
        recipients[0].amount = 2985000000000000000;
        recipients[1].recipient = payable(FEES);
        recipients[1].amount = 15000000000000000;

        SeaportProxy.OrderExtraData memory orderExtraData = _baseOrderExtraData();
        orderExtraData.salt = 0x360c6ebe0000000000000000000000000000000000000000b6397b96d24fe3df;
        orderExtraData.recipients = recipients;

        return abi.encode(orderExtraData);
    }

    function validMultifaucetId2828268OrderExtraData() internal pure returns (bytes memory) {
        AdditionalRecipient[] memory recipients = new AdditionalRecipient[](2);
        recipients[0].recipient = payable(OFFERER);
        recipients[0].amount = 1990000000000000000;
        recipients[1].recipient = payable(FEES);
        recipients[1].amount = 10000000000000000;

        SeaportProxy.OrderExtraData memory orderExtraData = _baseOrderExtraData();
        orderExtraData.salt = 0x360c6ebe00000000000000000000000000000000000000004d531ffe9843708d;
        orderExtraData.recipients = recipients;

        return abi.encode(orderExtraData);
    }

    function validMultifaucetId2828270OrderExtraData() internal pure returns (bytes memory) {
        AdditionalRecipient[] memory recipients = new AdditionalRecipient[](2);
        recipients[0].recipient = payable(OFFERER);
        recipients[0].amount = 995000000000000000;
        recipients[1].recipient = payable(FEES);
        recipients[1].amount = 5000000000000000;

        SeaportProxy.OrderExtraData memory orderExtraData = _baseOrderExtraData();
        orderExtraData.salt = 0x360c6ebe00000000000000000000000000000000000000007bb02b6dac7688cf;
        orderExtraData.recipients = recipients;

        return abi.encode(orderExtraData);
    }

    function _baseOrderExtraData() private pure returns (SeaportProxy.OrderExtraData memory orderExtraData) {
        orderExtraData.numerator = 1;
        orderExtraData.denominator = 1;
        orderExtraData.orderType = OrderType.FULL_OPEN;
        orderExtraData.zone = address(0);
        orderExtraData.zoneHash = bytes32(0);
        orderExtraData.conduitKey = 0x0000007b02230091a7ed01230072f7006a004d60a8d4e71d599b8104250f0000;
    }

    function validMultipleItemsSameCollectionExtraData() internal pure returns (bytes memory) {
        SeaportProxy.ExtraData memory extraData;

        extraData.offerFulfillments = validMultipleOfferFulfillments(2);
        extraData.considerationFulfillments = validMultipleConsiderationFulfillments();

        return abi.encode(extraData);
    }

    function validMultipleOfferFulfillments(uint256 numberOfOffers)
        internal
        pure
        returns (FulfillmentComponent[][] memory offerFulfillments)
    {
        offerFulfillments = new FulfillmentComponent[][](numberOfOffers);

        for (uint256 i; i < numberOfOffers; ) {
            offerFulfillments[i] = new FulfillmentComponent[](1);
            offerFulfillments[i][0].orderIndex = i;
            offerFulfillments[i][0].itemIndex = 0;

            unchecked {
                ++i;
            }
        }
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
}
