// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import {IX2Y2Run} from "../interfaces/IX2Y2Run.sol";
import {BasicOrder} from "../libraries/OrderStructs.sol";
import {Market} from "../libraries/MarketConsts.sol";
import {SignatureSplitter} from "../libraries/SignatureSplitter.sol";

contract X2Y2Proxy {
    IX2Y2Run public constant MARKETPLACE = IX2Y2Run(0x74312363e45DCaBA76c59ec49a7Aa8A65a67EeD3);

    struct OrderExtraData {
        uint256 salt;
        bytes itemData;
        address executionDelegate;
        Market.Fee[] fees;
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

        runInput.shared.salt = extraDataStruct.salt;
        runInput.shared.deadline = extraDataStruct.deadline;
        runInput.shared.amountToEth = 0;
        runInput.shared.amountToWeth = 0;
        runInput.shared.user = address(this);
        runInput.shared.canFail = false;

        Market.Order[] memory x2y2Orders = new Market.Order[](ordersLength);
        Market.SettleDetail[] memory details = new Market.SettleDetail[](ordersLength);

        for (uint256 i; i < ordersLength; ) {
            if (orders[i].recipient == address(0)) revert ZeroAddress();

            BasicOrder memory order = orders[i];

            OrderExtraData memory orderExtraData = abi.decode(ordersExtraData[i], (OrderExtraData));

            x2y2Orders[i].salt = orderExtraData.salt;
            x2y2Orders[i].user = orders[i].signer;
            x2y2Orders[i].network = block.chainid;
            x2y2Orders[i].intent = Market.INTENT_SELL;
            // X2Y2 enums start with INVALID so plus 1
            x2y2Orders[i].delegateType = uint256(orders[i].collectionType) + 1;
            x2y2Orders[i].deadline = orders[i].endTime;
            x2y2Orders[i].currency = address(0);
            x2y2Orders[i].dataMask = "0x";
            x2y2Orders[i].signVersion = Market.SIGN_V1;
            Market.OrderItem[] memory items = new Market.OrderItem[](1);
            items[0].price = orders[i].price;
            items[0].data = orderExtraData.itemData;
            x2y2Orders[i].items = items;

            details[i].op = Market.Op.COMPLETE_SELL_OFFER;
            details[i].bidIncentivePct = 0;
            details[i].aucMinIncrementPct = 0;
            details[i].aucIncDurationSecs = 0;
            details[i].executionDelegate = orderExtraData.executionDelegate;
            details[i].dataReplacement = "0x";
            details[i].orderIdx = 0;
            details[i].itemIdx = 0;
            details[i].price = orders[i].price;
            details[i].itemHash = _hashItem(x2y2Orders[i], items[0]);
            details[i].fees = orderExtraData.fees;

            (uint8 v, bytes32 r, bytes32 s) = SignatureSplitter.splitSignature(order.signature);
            x2y2Orders[i].r = r;
            x2y2Orders[i].s = s;
            x2y2Orders[i].v = v;
        }

        runInput.orders = x2y2Orders;
        runInput.details = details;
    }

    function _hashItem(Market.Order memory order, Market.OrderItem memory item)
        internal
        view
        virtual
        returns (bytes32)
    {
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
