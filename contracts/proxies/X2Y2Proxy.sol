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
        uint256 inputSalt;
        uint256 inputDeadline;
        uint8 inputV;
        bytes32 inputR;
        bytes32 inputS;
    }

    // TODO: make a BaseProxy / IProxy
    error InvalidOrderLength();
    error ZeroAddress();

    function buyWithETH(
        BasicOrder[] calldata orders,
        bytes[] calldata ordersExtraData,
        bytes calldata
    ) external payable {
        uint256 ordersLength = orders.length;
        if (ordersLength == 0 || ordersLength != ordersExtraData.length) revert InvalidOrderLength();

        for (uint256 i; i < ordersLength; ) {
            if (orders[i].recipient == address(0)) revert ZeroAddress();
            OrderExtraData memory orderExtraData = abi.decode(ordersExtraData[i], (OrderExtraData));
            _executeOrder(orders[i], orderExtraData);
        }
    }

    function _executeOrder(BasicOrder calldata order, OrderExtraData memory orderExtraData) private {
        if (order.recipient == address(0)) revert ZeroAddress();

        Market.RunInput memory runInput;

        runInput.r = orderExtraData.inputR;
        runInput.s = orderExtraData.inputS;
        runInput.v = orderExtraData.inputV;

        runInput.shared.salt = orderExtraData.inputSalt;
        runInput.shared.deadline = orderExtraData.inputDeadline;
        runInput.shared.amountToEth = 0;
        runInput.shared.amountToWeth = 0;
        runInput.shared.user = address(this);
        runInput.shared.canFail = false;

        runInput.orders[0].salt = orderExtraData.salt;
        runInput.orders[0].user = order.signer;
        runInput.orders[0].network = block.chainid;
        runInput.orders[0].intent = Market.INTENT_SELL;
        // X2Y2 enums start with INVALID so plus 1
        runInput.orders[0].delegateType = uint256(order.collectionType) + 1;
        runInput.orders[0].deadline = order.endTime;
        runInput.orders[0].currency = order.currency;
        runInput.orders[0].dataMask = "0x";
        runInput.orders[0].signVersion = Market.SIGN_V1;

        runInput.orders[0].items[0].price = order.price;
        runInput.orders[0].items[0].data = orderExtraData.itemData;

        runInput.details[0].op = Market.Op.COMPLETE_SELL_OFFER;
        runInput.details[0].bidIncentivePct = 0;
        runInput.details[0].aucMinIncrementPct = 0;
        runInput.details[0].aucIncDurationSecs = 0;
        runInput.details[0].executionDelegate = orderExtraData.executionDelegate;
        runInput.details[0].dataReplacement = "0x";
        runInput.details[0].orderIdx = 0;
        runInput.details[0].itemIdx = 0;
        runInput.details[0].price = order.price;
        runInput.details[0].itemHash = _hashItem(runInput.orders[0], runInput.orders[0].items[0]);
        runInput.details[0].fees = orderExtraData.fees;

        (uint8 v, bytes32 r, bytes32 s) = SignatureSplitter.splitSignature(order.signature);
        runInput.orders[0].r = r;
        runInput.orders[0].s = s;
        runInput.orders[0].v = v;

        try MARKETPLACE.run{value: order.price}(runInput) {} catch {}
    }

    function _hashItem(Market.Order memory order, Market.OrderItem memory item) private view returns (bytes32) {
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
