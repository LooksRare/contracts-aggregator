// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {IX2Y2Run} from "../interfaces/IX2Y2Run.sol";
import {BasicOrder} from "../libraries/OrderStructs.sol";
import {Market} from "../libraries/x2y2/MarketConsts.sol";
import {SignatureSplitter} from "../libraries/SignatureSplitter.sol";
import {CollectionType} from "../libraries/OrderEnums.sol";
import {TokenReceiverProxy} from "./TokenReceiverProxy.sol";
import {LowLevelETH} from "../lowLevelCallers/LowLevelETH.sol";

/**
 * @title X2Y2Proxy
 * @notice This contract allows NFT sweepers to batch buy NFTs from X2Y2Proxy
 *         by passing high-level structs + low-level bytes as calldata.
 * @author LooksRare protocol team (👀,💎)
 */
contract X2Y2Proxy is TokenReceiverProxy, LowLevelETH {
    IX2Y2Run public constant MARKETPLACE = IX2Y2Run(0x74312363e45DCaBA76c59ec49a7Aa8A65a67EeD3);

    struct OrderExtraData {
        uint256 salt; // An arbitrary source of entropy for the order (per trade)
        bytes itemData; // The data of the token to be traded (id, address, etc)
        uint256 inputSalt; // An arbitrary source of entropy for the order (for the whole order)
        uint256 inputDeadline; // order deadline
        address executionDelegate; // The contract to execute the trade
        uint8 inputV; // v parameter of the order signature signed by an authorized signer (not the seller)
        bytes32 inputR; // r parameter of the order signature signed by an authorized signer (not the seller)
        bytes32 inputS; // s parameter of the order signature signed by an authorized signer (not the seller)
        Market.Fee[] fees; // An array of sales proceeds recipient and the % for each of them
    }

    /// @notice Execute X2Y2 NFT sweeps in a single transaction
    /// @dev The 3rd argument extraData is not used
    /// @param orders Orders to be executed by Seaport
    /// @param ordersExtraData Extra data for each order
    /// @param isAtomic Flag to enable atomic trades (all or nothing) or partial trades
    /// @return Whether at least 1 out of N trades succeeded
    function buyWithETH(
        BasicOrder[] calldata orders,
        bytes[] calldata ordersExtraData,
        bytes calldata,
        bool isAtomic
    ) external payable override returns (bool) {
        uint256 ordersLength = orders.length;
        if (ordersLength == 0 || ordersLength != ordersExtraData.length) revert InvalidOrderLength();

        uint256 executedCount;
        for (uint256 i; i < ordersLength; ) {
            if (orders[i].recipient == address(0)) revert ZeroAddress();
            OrderExtraData memory orderExtraData = abi.decode(ordersExtraData[i], (OrderExtraData));
            bool executed = _executeSingleOrder(orders[i], orderExtraData, isAtomic);
            if (executed) executedCount += 1;

            unchecked {
                ++i;
            }
        }

        _returnETHIfAny(tx.origin);

        return executedCount > 0;
    }

    function _executeSingleOrder(
        BasicOrder calldata order,
        OrderExtraData memory orderExtraData,
        bool isAtomic
    ) private returns (bool executed) {
        if (order.recipient == address(0)) revert ZeroAddress();

        Market.RunInput memory runInput;

        runInput.r = orderExtraData.inputR;
        runInput.s = orderExtraData.inputS;
        runInput.v = orderExtraData.inputV;

        // amountToEth and amountToWeth default is 0
        runInput.shared.salt = orderExtraData.inputSalt;
        runInput.shared.deadline = orderExtraData.inputDeadline;
        runInput.shared.user = address(this);
        // canFail default is false

        Market.Order[] memory x2y2Orders = new Market.Order[](1);
        x2y2Orders[0].salt = orderExtraData.salt;
        x2y2Orders[0].user = order.signer;
        x2y2Orders[0].network = block.chainid;
        x2y2Orders[0].intent = Market.INTENT_SELL;
        // X2Y2 enums start with INVALID so plus 1
        x2y2Orders[0].delegateType = uint256(order.collectionType) + 1;
        x2y2Orders[0].deadline = order.endTime;
        x2y2Orders[0].currency = order.currency;
        // dataMask default is 0 bytes
        x2y2Orders[0].signVersion = Market.SIGN_V1;

        Market.OrderItem[] memory items = new Market.OrderItem[](1);
        items[0].price = order.price;
        items[0].data = orderExtraData.itemData;
        x2y2Orders[0].items = items;

        runInput.orders = x2y2Orders;

        Market.SettleDetail[] memory settleDetails = new Market.SettleDetail[](1);
        settleDetails[0].op = Market.Op.COMPLETE_SELL_OFFER;
        // bidIncentivePct/aucMinIncrementPct/aucIncDurationSecs default is 0
        settleDetails[0].executionDelegate = orderExtraData.executionDelegate;
        // dataReplacement/orderIdx/itemIdx default is 0
        settleDetails[0].price = order.price;
        settleDetails[0].itemHash = _hashItem(runInput.orders[0], runInput.orders[0].items[0]);
        settleDetails[0].fees = orderExtraData.fees;
        runInput.details = settleDetails;

        (uint8 v, bytes32 r, bytes32 s) = SignatureSplitter.splitSignature(order.signature);
        runInput.orders[0].r = r;
        runInput.orders[0].s = s;
        runInput.orders[0].v = v;

        if (isAtomic) {
            MARKETPLACE.run{value: order.price}(runInput);
            _transferTokenToRecipient(
                order.collectionType,
                order.recipient,
                order.collection,
                order.tokenIds[0],
                order.amounts[0]
            );
            executed = true;
        } else {
            try MARKETPLACE.run{value: order.price}(runInput) {
                _transferTokenToRecipient(
                    order.collectionType,
                    order.recipient,
                    order.collection,
                    order.tokenIds[0],
                    order.amounts[0]
                );
                executed = true;
            } catch {}
        }
    }

    function _hashItem(Market.Order memory order, Market.OrderItem memory item) private pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    order.salt,
                    order.user,
                    order.network,
                    order.intent,
                    order.delegateType,
                    order.deadline,
                    order.currency,
                    order.dataMask,
                    item
                )
            );
    }
}
