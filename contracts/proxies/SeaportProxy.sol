// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SeaportInterface} from "../interfaces/SeaportInterface.sol";
import {BasicOrder, TokenTransfer} from "../libraries/OrderStructs.sol";
import {CollectionType} from "../libraries/OrderEnums.sol";
import {AdvancedOrder, CriteriaResolver, OrderParameters, OfferItem, ConsiderationItem, FulfillmentComponent, AdditionalRecipient} from "../libraries/seaport/ConsiderationStructs.sol";
import {ItemType, OrderType} from "../libraries/seaport/ConsiderationEnums.sol";
import {TokenLogic} from "../TokenLogic.sol";
import {IProxy} from "../proxies/IProxy.sol";

/**
 * @title SeaportProxy
 * @notice This contract allows NFT sweepers to batch buy NFTs from Seaport
 *         by passing high-level structs + low-level bytes as calldata.
 * @author LooksRare protocol team (👀,💎)
 */
contract SeaportProxy is TokenLogic, IProxy {
    SeaportInterface public immutable marketplace;

    error TradeExecutionFailed();

    struct ExtraData {
        FulfillmentComponent[][] offerFulfillments; // Contains the order and item index of each offer item
        FulfillmentComponent[][] considerationFulfillments; // Contains the order and item index of each consideration item
    }

    struct OrderExtraData {
        uint120 numerator; // A fraction to attempt to fill
        uint120 denominator; // The total size of the order
        OrderType orderType; // Seaport order type
        address zone; // A zone can cancel the order or restrict who can fulfill the order depending on the type
        bytes32 zoneHash; // An arbitrary 32-byte value that will be supplied to the zone when fulfilling restricted orders that the zone can utilize when making a determination on whether to authorize the order
        uint256 salt; // An arbitrary source of entropy for the order
        bytes32 conduitKey; // A bytes32 value that indicates what conduit, if any, should be utilized as a source for token approvals when performing transfers
        AdditionalRecipient[] recipients; // Recipients of consideration items
    }

    /**
     * @param _marketplace Seaport's address
     */
    constructor(address _marketplace) {
        marketplace = SeaportInterface(_marketplace);
    }

    /**
     * @notice Execute Seaport NFT sweeps in a single transaction
     * @param tokenTransfers Aggregated ERC-20 token transfers for all orders
     * @param orders Orders to be executed by Seaport
     * @param ordersExtraData Extra data for each order
     * @param extraData Extra data for the whole transaction
     * @param recipient The address to receive the purchased NFTs
     * @param isAtomic Flag to enable atomic trades (all or nothing) or partial trades
     * @return Whether at least 1 out of N trades succeeded
     */
    function execute(
        TokenTransfer[] calldata tokenTransfers,
        BasicOrder[] calldata orders,
        bytes[] calldata ordersExtraData,
        bytes calldata extraData,
        address recipient,
        bool isAtomic
    ) external payable override returns (bool) {
        uint256 ordersLength = orders.length;
        if (ordersLength == 0 || ordersLength != ordersExtraData.length) revert InvalidOrderLength();
        if (recipient == address(0)) revert ZeroAddress();

        if (tokenTransfers.length > 0) _pullERC20Tokens(tokenTransfers, msg.sender);

        if (isAtomic) {
            _executeAtomicOrders(orders, ordersExtraData, extraData, recipient);
            if (tokenTransfers.length > 0) _returnERC20TokensIfAny(tokenTransfers, msg.sender);
            _returnETHIfAny();
            return true;
        } else {
            uint256 executedCount = _executeNonAtomicOrders(orders, ordersExtraData, recipient);
            if (tokenTransfers.length > 0) _returnERC20TokensIfAny(tokenTransfers, msg.sender);
            _returnETHIfAny();
            return executedCount > 0;
        }
    }

    /**
     * @notice Approve Seaport to transfer ERC-20 tokens from the proxy
     * @param currency The address of the ERC-20 token to approve
     */
    function approve(address currency) external onlyOwner {
        IERC20(currency).approve(address(marketplace), type(uint256).max);
    }

    /**
     * @notice Revoke Seaport's approval to transfer ERC-20 tokens from the proxy
     * @param currency The address of the ERC-20 token to revoke
     */
    function revoke(address currency) external onlyOwner {
        IERC20(currency).approve(address(marketplace), 0);
    }

    /**
     * @dev If fulfillAvailableAdvancedOrders fails, the ETH paid to Seaport
     *      is refunded to the proxy contract. The proxy then has to refund
     *      the ETH back to the user through _returnETHIfAny.
     */
    receive() external payable {}

    function _executeAtomicOrders(
        BasicOrder[] calldata orders,
        bytes[] calldata ordersExtraData,
        bytes calldata extraData,
        address recipient
    ) private {
        uint256 ordersLength = orders.length;
        AdvancedOrder[] memory advancedOrders = new AdvancedOrder[](ordersLength);
        ExtraData memory extraDataStruct = abi.decode(extraData, (ExtraData));
        CriteriaResolver[] memory criteriaResolver = new CriteriaResolver[](0);

        for (uint256 i; i < ordersLength; ) {
            OrderExtraData memory orderExtraData = abi.decode(ordersExtraData[i], (OrderExtraData));
            advancedOrders[i].parameters = _populateParameters(orders[i], orderExtraData);
            advancedOrders[i].numerator = orderExtraData.numerator;
            advancedOrders[i].denominator = orderExtraData.denominator;
            advancedOrders[i].signature = orders[i].signature;

            unchecked {
                ++i;
            }
        }

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
    }

    function _executeNonAtomicOrders(
        BasicOrder[] calldata orders,
        bytes[] calldata ordersExtraData,
        address recipient
    ) private returns (uint256 executedCount) {
        CriteriaResolver[] memory criteriaResolver = new CriteriaResolver[](0);
        uint256 ordersLength = orders.length;
        for (uint256 i; i < ordersLength; ) {
            OrderExtraData memory orderExtraData = abi.decode(ordersExtraData[i], (OrderExtraData));
            AdvancedOrder memory advancedOrder;
            advancedOrder.parameters = _populateParameters(orders[i], orderExtraData);
            advancedOrder.numerator = 1;
            advancedOrder.denominator = 1;
            advancedOrder.signature = orders[i].signature;

            uint256 price = orders[i].currency == address(0) ? orders[i].price : 0;

            try marketplace.fulfillAdvancedOrder{value: price}(advancedOrder, criteriaResolver, bytes32(0), recipient) {
                executedCount += 1;
            } catch {}

            unchecked {
                ++i;
            }
        }
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
            // We don't need to assign value to identifierOrCriteria as it is always 0.
            consideration[j].startAmount = orderExtraData.recipients[j].amount;
            consideration[j].endAmount = orderExtraData.recipients[j].amount;
            consideration[j].recipient = payable(orderExtraData.recipients[j].recipient);
            consideration[j].itemType = order.currency == address(0) ? ItemType.NATIVE : ItemType.ERC20;
            consideration[j].token = order.currency;

            unchecked {
                ++j;
            }
        }
        parameters.consideration = consideration;
    }
}
