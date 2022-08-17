// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import {SeaportInterface} from "../interfaces/SeaportInterface.sol";
import {BasicOrder} from "../libraries/OrderStructs.sol";
import {CollectionType} from "../libraries/OrderEnums.sol";
import {AdvancedOrder, CriteriaResolver, OrderParameters, OfferItem, ConsiderationItem, FulfillmentComponent} from "../libraries/seaport/ConsiderationStructs.sol";
import {ItemType, OrderType} from "../libraries/seaport/ConsiderationEnums.sol";
import {LowLevelETH} from "../lowLevelCallers/LowLevelETH.sol";
import {IProxy} from "./IProxy.sol";

/**
 * @title SeaportProxy
 * @notice This contract allows NFT sweepers to batch buy NFTs from Seaport
 *         by passing high-level structs + low-level bytes as calldata.
 * @author LooksRare protocol team (👀,💎)
 */
contract SeaportProxy is LowLevelETH, IProxy {
    SeaportInterface constant MARKETPLACE = SeaportInterface(0x00000000006c3852cbEf3e08E8dF289169EdE581);

    struct Recipient {
        address recipient; // Sale proceeds recipient, typically it is the address of seller/OpenSea Fees/royalty
        uint256 amount; // Amount of ETH to send to the recipient
    }

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
        Recipient[] recipients; // Recipients of consideration items
    }

    /// @notice Execute Seaport NFT sweeps in a single transaction
    /// @dev The 4th argument isAtomic is not used because there is only 1 call to Seaport
    /// @param orders Orders to be executed by Seaport
    /// @param ordersExtraData Extra data for each order
    /// @return Whether at least 1 out of N trades succeeded
    function buyWithETH(
        BasicOrder[] calldata orders,
        bytes[] calldata ordersExtraData,
        bytes calldata extraData,
        bool
    ) external payable override returns (bool) {
        uint256 ordersLength = orders.length;
        if (ordersLength == 0 || ordersLength != ordersExtraData.length) revert InvalidOrderLength();

        address recipient = orders[0].recipient;
        // Since Seaport supports custom recipient, the recipient should not be the proxy.
        if (recipient == address(this)) revert InvalidRecipient();
        if (recipient == address(0)) revert ZeroAddress();

        AdvancedOrder[] memory advancedOrders = new AdvancedOrder[](orders.length);
        ExtraData memory extraDataStruct = abi.decode(extraData, (ExtraData));

        for (uint256 i; i < orders.length; ) {
            OrderExtraData memory orderExtraData = abi.decode(ordersExtraData[i], (OrderExtraData));
            advancedOrders[i].parameters = _populateParameters(orders[i], orderExtraData);
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

        return true;
    }

    /**
     * @dev If fulfillAvailableAdvancedOrders fails, the ETH paid to Seaport
     *      is refunded to the proxy contract. The proxy then has to refund
     *      the ETH back to the user.
     */
    receive() external payable {
        _transferETH(tx.origin, msg.value);
    }

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
