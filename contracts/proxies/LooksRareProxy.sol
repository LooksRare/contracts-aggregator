// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "../interfaces/ILooksRareV1.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {BasicOrder} from "../libraries/OrderStructs.sol";
import {CollectionType} from "../libraries/OrderEnums.sol";
import {SignatureSplitter} from "../libraries/SignatureSplitter.sol";
import {TokenReceiverProxy} from "./TokenReceiverProxy.sol";

contract LooksRareProxy is TokenReceiverProxy {
    struct OrderExtraData {
        address strategy;
        uint256 nonce;
        uint256 minPercentageToAsk;
    }

    ILooksRareV1 constant MARKETPLACE = ILooksRareV1(0x59728544B08AB483533076417FbBB2fD0B17CE3a);

    error InvalidOrderLength();
    error ZeroAddress();

    function buyWithETH(
        BasicOrder[] calldata orders,
        bytes[] calldata ordersExtraData,
        bytes memory
    ) external payable {
        uint256 ordersLength = orders.length;
        if (ordersLength == 0 || ordersLength != ordersExtraData.length) revert InvalidOrderLength();
        for (uint256 i; i < ordersLength; ) {
            if (orders[i].recipient == address(0)) revert ZeroAddress();

            BasicOrder memory order = orders[i];

            OrderExtraData memory orderExtraData = abi.decode(ordersExtraData[i], (OrderExtraData));

            ILooksRareV1.MakerOrder memory makerAsk;
            makerAsk.isOrderAsk = true;
            makerAsk.signer = order.signer;
            makerAsk.collection = order.collection;
            makerAsk.tokenId = order.tokenIds[0];
            makerAsk.price = order.price;
            makerAsk.amount = order.amounts[0];
            makerAsk.strategy = orderExtraData.strategy;
            makerAsk.nonce = orderExtraData.nonce;
            makerAsk.minPercentageToAsk = orderExtraData.minPercentageToAsk;
            makerAsk.currency = order.currency;
            makerAsk.startTime = order.startTime;
            makerAsk.endTime = order.endTime;

            (uint8 v, bytes32 r, bytes32 s) = SignatureSplitter.splitSignature(order.signature);
            makerAsk.v = v;
            makerAsk.r = r;
            makerAsk.s = s;

            ILooksRareV1.TakerOrder memory takerBid;
            takerBid.isOrderAsk = false;
            takerBid.taker = address(this);
            takerBid.price = order.price;
            takerBid.tokenId = order.tokenIds[0];
            takerBid.minPercentageToAsk = orderExtraData.minPercentageToAsk;

            _matchSingleOrder(takerBid, makerAsk, order.recipient, order.collectionType);

            unchecked {
                ++i;
            }
        }
    }

    function _matchSingleOrder(
        ILooksRareV1.TakerOrder memory takerBid,
        ILooksRareV1.MakerOrder memory makerAsk,
        address recipient,
        CollectionType collectionType
    ) private {
        try MARKETPLACE.matchAskWithTakerBidUsingETHAndWETH{value: makerAsk.price}(takerBid, makerAsk) {
            _transferTokenToRecipient(
                collectionType,
                recipient,
                makerAsk.collection,
                makerAsk.tokenId,
                makerAsk.amount
            );
        } catch (bytes memory returnData) {
            if (returnData.length > 0) {
                assembly {
                    let returnDataSize := mload(returnData)
                    revert(add(32, returnData), returnDataSize)
                }
            } else {}
        }
    }
}
