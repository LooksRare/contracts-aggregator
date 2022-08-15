// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {IX2Y2Run} from "../interfaces/IX2Y2Run.sol";
import {BasicOrder} from "../libraries/OrderStructs.sol";
import {Market} from "../libraries/MarketConsts.sol";
import {SignatureSplitter} from "../libraries/SignatureSplitter.sol";
import {CollectionType} from "../libraries/OrderEnums.sol";
import "hardhat/console.sol";

contract X2Y2Proxy {
    IX2Y2Run public constant MARKETPLACE = IX2Y2Run(0x74312363e45DCaBA76c59ec49a7Aa8A65a67EeD3);

    struct OrderExtraData {
        uint256 salt;
        bytes itemData;
        address executionDelegate;
        uint256 inputSalt;
        uint256 inputDeadline;
        uint8 inputV;
        bytes32 inputR;
        bytes32 inputS;
        Market.Fee[] fees;
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

            unchecked {
                ++i;
            }
        }
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
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

        Market.Order[] memory x2y2Orders = new Market.Order[](1);
        x2y2Orders[0].salt = orderExtraData.salt;
        x2y2Orders[0].user = order.signer;
        x2y2Orders[0].network = 1;
        // runInput.orders[0].network = block.chainid;
        x2y2Orders[0].intent = Market.INTENT_SELL;
        // X2Y2 enums start with INVALID so plus 1
        x2y2Orders[0].delegateType = uint256(order.collectionType) + 1;
        x2y2Orders[0].deadline = order.endTime;
        x2y2Orders[0].currency = order.currency;
        // x2y2Orders[0].dataMask = "0x";
        x2y2Orders[0].signVersion = Market.SIGN_V1;

        Market.OrderItem[] memory items = new Market.OrderItem[](1);
        items[0].price = order.price;
        items[0].data = orderExtraData.itemData;
        x2y2Orders[0].items = items;

        runInput.orders = x2y2Orders;

        Market.SettleDetail[] memory settleDetails = new Market.SettleDetail[](1);
        settleDetails[0].op = Market.Op.COMPLETE_SELL_OFFER;
        settleDetails[0].bidIncentivePct = 0;
        settleDetails[0].aucMinIncrementPct = 0;
        settleDetails[0].aucIncDurationSecs = 0;
        settleDetails[0].executionDelegate = orderExtraData.executionDelegate;
        // settleDetails[0].dataReplacement = "0x";
        settleDetails[0].orderIdx = 0;
        settleDetails[0].itemIdx = 0;
        settleDetails[0].price = order.price;
        settleDetails[0].itemHash = _hashItem(runInput.orders[0], runInput.orders[0].items[0]);
        settleDetails[0].fees = orderExtraData.fees;
        runInput.details = settleDetails;

        (uint8 v, bytes32 r, bytes32 s) = SignatureSplitter.splitSignature(order.signature);
        runInput.orders[0].r = r;
        runInput.orders[0].s = s;
        runInput.orders[0].v = v;

        try MARKETPLACE.run{value: order.price}(runInput) {
            if (order.collectionType == CollectionType.ERC721) {
                IERC721(order.collection).transferFrom(address(this), order.recipient, order.tokenIds[0]);
            } else if (order.collectionType == CollectionType.ERC1155) {
                IERC1155(order.collection).safeTransferFrom(
                    address(this),
                    order.recipient,
                    order.tokenIds[0],
                    order.amounts[0],
                    "0x"
                );
            }
        } catch (bytes memory err) {
            console.log("FAILED!!!!");
            console.logBytes(err);
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
