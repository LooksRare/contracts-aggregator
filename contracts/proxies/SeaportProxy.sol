// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import {SeaportInterface} from "../interfaces/SeaportInterface.sol";
import {BasicOrder} from "../libraries/OrderStructs.sol";
import {CollectionType} from "../libraries/OrderEnums.sol";
import {AdvancedOrder, CriteriaResolver, OrderParameters, OfferItem, ConsiderationItem, FulfillmentComponent, AdditionalRecipient} from "../libraries/seaport/ConsiderationStructs.sol";
import {ItemType, OrderType} from "../libraries/seaport/ConsiderationEnums.sol";
import {TokenRescuer} from "../TokenRescuer.sol";
import {IProxy} from "../proxies/IProxy.sol";

/**
 * @title SeaportProxy
 * @notice This contract allows NFT sweepers to batch buy NFTs from Seaport
 *         by passing high-level structs + low-level bytes as calldata.
 * @author LooksRare protocol team (👀,💎)
 */
contract SeaportProxy is TokenRescuer, IProxy {
    SeaportInterface public immutable marketplace;

    error TradeExecutionFailed();

    struct ExtraData {
        FulfillmentComponent[][] offerFulfillments; // Contains the order and item index of each offer item
        FulfillmentComponent[][] considerationFulfillments; // Contains the order and item index of each consideration item
    }

    struct OrderExtraData {
        OrderType orderType; // Seaport order type
        address zone; // A zone can cancel the order or restrict who can fulfill the order depending on the type
        bytes32 zoneHash; // An arbitrary 32-byte value that will be supplied to the zone when fulfilling restricted orders that the zone can utilize when making a determination on whether to authorize the order
        uint256 salt; // An arbitrary source of entropy for the order
        bytes32 conduitKey; // A bytes32 value that indicates what conduit, if any, should be utilized as a source for token approvals when performing transfers
        AdditionalRecipient[] recipients; // Recipients of consideration items
    }

    constructor(address _marketplace) {
        marketplace = SeaportInterface(_marketplace);
    }

    /**
     * @notice Execute Seaport NFT sweeps in a single transaction
     * @param orders Orders to be executed by Seaport
     * @param ordersExtraData Extra data for each order
     * @param extraData Extra data for the whole transaction
     * @param recipient The address to receive the purchased NFTs
     * @param isAtomic Flag to enable atomic trades (all or nothing) or partial trades
     * @return Whether at least 1 out of N trades succeeded
     */
    function buyWithETH(
        BasicOrder[] calldata orders,
        bytes[] calldata ordersExtraData,
        bytes calldata extraData,
        address recipient,
        bool isAtomic
    ) external payable override returns (bool) {
        uint256 ordersLength = orders.length;
        if (ordersLength == 0 || ordersLength != ordersExtraData.length) revert InvalidOrderLength();

        if (recipient == address(0)) revert ZeroAddress();

        CriteriaResolver[] memory criteriaResolver = new CriteriaResolver[](0);

        if (isAtomic) {
            AdvancedOrder[] memory advancedOrders = new AdvancedOrder[](ordersLength);
            ExtraData memory extraDataStruct = abi.decode(extraData, (ExtraData));

            for (uint256 i; i < ordersLength; ) {
                OrderExtraData memory orderExtraData = abi.decode(ordersExtraData[i], (OrderExtraData));
                advancedOrders[i].parameters = _populateParameters(orders[i], orderExtraData);
                advancedOrders[i].numerator = 1;
                advancedOrders[i].denominator = 1;
                advancedOrders[i].signature = orders[i].signature;

                unchecked {
                    ++i;
                }
            }

            // There is no need to do a try/catch here as there is only 1 external call
            // and if it fails the aggregator will catch it and decide whether to revert.
            (bool[] memory availableOrders, ) = marketplace.fulfillAvailableAdvancedOrders{value: msg.value}(
                advancedOrders,
                criteriaResolver,
                extraDataStruct.offerFulfillments,
                extraDataStruct.considerationFulfillments,
                bytes32(0),
                recipient,
                ordersLength
            );

            for (uint256 i; i < availableOrders.length; ) {
                if (!availableOrders[i]) revert TradeExecutionFailed();

                unchecked {
                    ++i;
                }
            }

            _returnETHIfAny();

            return true;
        } else {
            uint256 executedCount;

            for (uint256 i; i < ordersLength; ) {
                OrderExtraData memory orderExtraData = abi.decode(ordersExtraData[i], (OrderExtraData));
                AdvancedOrder memory advancedOrder;
                advancedOrder.parameters = _populateParameters(orders[i], orderExtraData);
                advancedOrder.numerator = 1;
                advancedOrder.denominator = 1;
                advancedOrder.signature = orders[i].signature;

                uint256 price = orders[i].price;

                try
                    marketplace.fulfillAdvancedOrder{value: price}(
                        advancedOrder,
                        criteriaResolver,
                        bytes32(0),
                        recipient
                    )
                {
                    executedCount += 1;
                } catch {}

                unchecked {
                    ++i;
                }
            }

            _returnETHIfAny();

            return executedCount > 0;
        }
    }

    /**
     * @dev If fulfillAvailableAdvancedOrders fails, the ETH paid to Seaport
     *      is refunded to the proxy contract. The proxy then has to refund
     *      the ETH back to the user through _returnETHIfAny.
     */
    receive() external payable {}

    function _populateParameters(BasicOrder calldata order, OrderExtraData memory orderExtraData)
        private
        pure
        returns (OrderParameters memory parameters)
    {
        uint256 recipientsLength = orderExtraData.recipients.length;

        parameters.offerer = order.signer;
        parameters.zone = orderExtraData.zone;
        parameters.zoneHash = orderExtraData.zoneHash;
        parameters.salt = orderExtraData.salt;
        parameters.conduitKey = orderExtraData.conduitKey;
        parameters.orderType = orderExtraData.orderType;
        parameters.startTime = order.startTime;
        parameters.endTime = order.endTime;
        parameters.totalOriginalConsiderationItems = recipientsLength;

        OfferItem[] memory offer = new OfferItem[](1);
        // Seaport enums start with NATIVE and ERC20 so plus 2
        offer[0].itemType = ItemType(uint8(order.collectionType) + 2);
        offer[0].token = order.collection;
        offer[0].identifierOrCriteria = order.tokenIds[0];
        offer[0].startAmount = order.amounts[0];
        offer[0].endAmount = order.amounts[0];
        parameters.offer = offer;

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
    }
}
