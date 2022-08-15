// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import {IX2Y2Run} from "../interfaces/IX2Y2Run.sol";
import {BasicOrder} from "../libraries/OrderStructs.sol";
import {Market} from "../libraries/MarketConsts.sol";
import {SignatureSplitter} from "../libraries/SignatureSplitter.sol";

contract X2Y2Proxy {
    IX2Y2Run public constant MARKETPLACE = IX2Y2Run(0x74312363e45DCaBA76c59ec49a7Aa8A65a67EeD3);

    // uint256 delegateType;
    // bytes dataMask;
    // OrderItem[] items;
    struct OrderExtraData {
        uint256 salt;
        bytes dataMask;
        bytes itemData;

        // Market.Op op;
        // uint256 orderIdx;
        // uint256 itemIdx;
        // uint256 price;
        // bytes32 itemHash;
        // address executionDelegate;
        // // IDelegate executionDelegate;
        // bytes dataReplacement;
        // uint256 bidIncentivePct;
        // uint256 aucMinIncrementPct;
        // uint256 aucIncDurationSecs;
        // Market.Fee[] fees;
    }

    struct ExtraData {
        uint256 salt;
        uint256 deadline;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    // TODO: make a BaseProxy / IProxy
    error InvalidOrderLength();
    error ZeroAddress();

    function buyWithETH(
        BasicOrder[] calldata orders,
        bytes[] calldata ordersExtraData,
        bytes calldata extraData
    ) external payable {
        uint256 ordersLength = orders.length;
        if (ordersLength == 0 || ordersLength != ordersExtraData.length) revert InvalidOrderLength();

        Market.RunInput memory runInput;

        ExtraData memory extraDataStruct = abi.decode(extraData, (ExtraData));

        runInput.r = extraDataStruct.r;
        runInput.s = extraDataStruct.s;
        runInput.v = extraDataStruct.v;

        Market.SettleShared memory settledShared;
        settledShared.salt = extraDataStruct.salt;
        settledShared.deadline = extraDataStruct.deadline;
        settledShared.amountToEth = 0;
        settledShared.amountToWeth = 0;
        settledShared.user = address(this);
        settledShared.canFail = false;

        runInput.shared = settledShared;

        Market.Order[] memory x2y2Orders = new Market.Order[](ordersLength);
        Market.SettleDetail[] memory details = new Market.SettleDetail[](ordersLength);

        for (uint256 i; i < ordersLength; ) {
            if (orders[i].recipient == address(0)) revert ZeroAddress();

            BasicOrder memory order = orders[i];

            OrderExtraData memory orderExtraData = abi.decode(ordersExtraData[i], (OrderExtraData));

            Market.Order memory x2y2Order;
            x2y2Order.salt = orderExtraData.salt;
            x2y2Order.user = orders[i].signer;
            x2y2Order.network = block.chainid;
            x2y2Order.intent = Market.INTENT_SELL;
            // X2Y2 enums start with INVALID so plus 1
            x2y2Order.delegateType = uint256(orders[i].collectionType) + 1;
            x2y2Order.deadline = orders[i].endTime;
            x2y2Order.currency = address(0);
            x2y2Order.dataMask = orderExtraData.dataMask;
            x2y2Order.signVersion = Market.SIGN_V1;
            Market.OrderItem[] memory items = new Market.OrderItem[](orders[i].tokenIds.length);
            for (uint256 j; j < orders[i].tokenIds.length; ) {
                Market.OrderItem memory item;
                item.price = orders[i].price;
                unchecked {
                    ++j;
                }
            }
            x2y2Orders.items = items;

            (uint8 v, bytes32 r, bytes32 s) = SignatureSplitter.splitSignature(order.signature);
            x2y2Order.r = extraDataStruct.r;
            x2y2Order.s = extraDataStruct.s;
            x2y2Order.v = extraDataStruct.v;
        }

        runInput.orders = x2y2Orders;
        runInput.details = details;
    }
}
