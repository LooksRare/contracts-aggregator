// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import {SeaportInterface} from "../interfaces/SeaportInterface.sol";
import {BasicOrder} from "../libraries/OrderStructs.sol";
import {AdvancedOrder, CriteriaResolver, OrderParameters, OfferItem, ConsiderationItem, FulfillmentComponent} from "../lib/ConsiderationStructs.sol";
import {ItemType, OrderType} from "../lib/ConsiderationEnums.sol";

import "hardhat/console.sol";

contract SeaportProxy {
    SeaportInterface constant MARKETPLACE = SeaportInterface(0x00000000006c3852cbEf3e08E8dF289169EdE581);

    struct Recipient {
        address recipient;
        uint256 amount;
    }

    // should item type be calculated using IERC165?
    struct ExtraData {
        FulfillmentComponent[][] offerFulfillments;
        FulfillmentComponent[][] considerationFulfillments;
    }

    struct OrderExtraData {
        OrderType orderType;
        address zone;
        bytes32 zoneHash;
        uint256 salt;
        bytes32 conduitKey;
        Recipient[] recipients;
    }

    error InvalidOrderLength();

    function buyWithETH(
        BasicOrder[] calldata orders,
        bytes[] calldata ordersExtraData,
        bytes calldata extraData
    ) external payable {
        uint256 ordersLength = orders.length;
        address recipient = orders[0].recipient;
        if (ordersLength == 0 || ordersLength != ordersExtraData.length) revert InvalidOrderLength();

        AdvancedOrder[] memory advancedOrders = new AdvancedOrder[](ordersLength);
        ExtraData memory extraDataStruct = abi.decode(extraData, (ExtraData));

        for (uint256 i; i < ordersLength; ) {
            OrderExtraData memory orderExtraData = abi.decode(ordersExtraData[i], (OrderExtraData));
            uint256 recipientsLength = orderExtraData.recipients.length;

            OrderParameters memory parameters;
            parameters.offerer = orders[i].signer;
            parameters.zone = orderExtraData.zone;
            parameters.zoneHash = orderExtraData.zoneHash;
            parameters.salt = orderExtraData.salt;
            parameters.conduitKey = orderExtraData.conduitKey;
            parameters.orderType = orderExtraData.orderType;
            parameters.startTime = orders[i].startTime;
            parameters.endTime = orders[i].endTime;
            parameters.totalOriginalConsiderationItems = recipientsLength;

            OfferItem[] memory offer = new OfferItem[](1);
            offer[0].itemType = ItemType.ERC721; // TODO: Support ERC-1155
            offer[0].token = orders[i].collection;
            offer[0].identifierOrCriteria = orders[i].tokenId;
            offer[0].startAmount = orders[i].amount;
            offer[0].endAmount = orders[i].amount;
            parameters.offer = offer;

            ConsiderationItem[] memory consideration = new ConsiderationItem[](recipientsLength);
            for (uint256 j; j < recipientsLength; ) {
                consideration[j].itemType = ItemType.NATIVE; // TODO: dynamic?
                consideration[j].token = address(0);
                consideration[j].identifierOrCriteria = 0;
                consideration[j].startAmount = orderExtraData.recipients[j].amount;
                consideration[j].endAmount = orderExtraData.recipients[j].amount;
                consideration[j].recipient = payable(orderExtraData.recipients[j].recipient);

                unchecked {
                    ++j;
                }
            }
            parameters.consideration = consideration;

            advancedOrders[i].parameters = parameters;
            advancedOrders[i].numerator = 1;
            advancedOrders[i].denominator = 1;
            advancedOrders[i].signature = orders[i].signature;

            unchecked {
                ++i;
            }
        }

        CriteriaResolver[] memory criteriaResolver = new CriteriaResolver[](0);

        MARKETPLACE.fulfillAvailableAdvancedOrders{value: msg.value}(
            advancedOrders,
            criteriaResolver,
            extraDataStruct.offerFulfillments,
            extraDataStruct.considerationFulfillments,
            bytes32(0),
            recipient, // TODO: Should we just use the first one or...?
            ordersLength
        );
    }
}
