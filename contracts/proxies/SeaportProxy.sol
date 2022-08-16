// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import {SeaportInterface} from "../interfaces/SeaportInterface.sol";
import {BasicOrder} from "../libraries/OrderStructs.sol";
import {CollectionType} from "../libraries/OrderEnums.sol";
import {AdvancedOrder, CriteriaResolver, OrderParameters, OfferItem, ConsiderationItem, FulfillmentComponent} from "../libraries/ConsiderationStructs.sol";
import {ItemType, OrderType} from "../libraries/ConsiderationEnums.sol";
import {LowLevelETH} from "../lowLevelCallers/LowLevelETH.sol";
import {IProxy} from "./IProxy.sol";

contract SeaportProxy is LowLevelETH, IProxy {
    SeaportInterface constant MARKETPLACE = SeaportInterface(0x00000000006c3852cbEf3e08E8dF289169EdE581);

    struct Recipient {
        address recipient;
        uint256 amount;
    }

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

    function buyWithETH(
        BasicOrder[] calldata orders,
        bytes[] calldata ordersExtraData,
        bytes calldata extraData,
        bool
    ) external payable override {
        uint256 ordersLength = orders.length;
        if (ordersLength == 0 || ordersLength != ordersExtraData.length) revert InvalidOrderLength();

        address recipient = orders[0].recipient;
        // Since Seaport supports custom recipient, the recipient should not be the proxy.
        if (recipient == address(this)) revert InvalidRecipient();
        if (recipient == address(0)) revert ZeroAddress();

        AdvancedOrder[] memory advancedOrders = new AdvancedOrder[](ordersLength);
        ExtraData memory extraDataStruct = abi.decode(extraData, (ExtraData));

        for (uint256 i; i < ordersLength; ) {
            OrderExtraData memory orderExtraData = abi.decode(ordersExtraData[i], (OrderExtraData));
            uint256 recipientsLength = orderExtraData.recipients.length;

            OrderParameters memory parameters;
            {
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
                // Seaport enums start with NATIVE and ERC20 so plus 2
                offer[0].itemType = ItemType(uint8(orders[i].collectionType) + 2);
                offer[0].token = orders[i].collection;
                offer[0].identifierOrCriteria = orders[i].tokenIds[0];
                offer[0].startAmount = orders[i].amounts[0];
                offer[0].endAmount = orders[i].amounts[0];
                parameters.offer = offer;
            }

            ConsiderationItem[] memory consideration = new ConsiderationItem[](recipientsLength);
            for (uint256 j; j < recipientsLength; ) {
                // We don't need to assign value to itemType/token/identifierOrCriteria as the default values are for ETH.
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

        // There is no need to do a try/catch here as there is only 1 external call
        // and if it fails the aggregator will catch it and decide whether to revert.
        MARKETPLACE.fulfillAvailableAdvancedOrders{value: msg.value}(
            advancedOrders,
            criteriaResolver,
            extraDataStruct.offerFulfillments,
            extraDataStruct.considerationFulfillments,
            bytes32(0),
            recipient,
            ordersLength
        );
    }

    /**
     * @dev If fulfillAvailableAdvancedOrders fails, the ETH paid to Seaport
     *      is refunded to the proxy contract. The proxy then has to refund
     *      the ETH back to the user.
     */
    receive() external payable {
        _transferETH(tx.origin, msg.value);
    }
}
