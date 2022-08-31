// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {ILooksRareExchange} from "@looksrare/contracts-exchange-v1/contracts/interfaces/ILooksRareExchange.sol";
import {OrderTypes} from "@looksrare/contracts-exchange-v1/contracts/libraries/OrderTypes.sol";
import {SignatureChecker} from "@looksrare/contracts-libs/contracts/SignatureChecker.sol";
import {BasicOrder, TokenTransfer} from "../libraries/OrderStructs.sol";
import {CollectionType} from "../libraries/OrderEnums.sol";
import {TokenReceiverProxy} from "./TokenReceiverProxy.sol";
import {TokenRescuer} from "../TokenRescuer.sol";

/**
 * @title LooksRareProxy
 * @notice This contract allows NFT sweepers to batch buy NFTs from LooksRare
 *         by passing high-level structs + low-level bytes as calldata.
 * @author LooksRare protocol team (👀,💎)
 */
contract LooksRareProxy is TokenReceiverProxy, TokenRescuer, SignatureChecker {
    struct OrderExtraData {
        uint256 makerAskPrice; // Maker ask price, which is not necessarily equal to the taker bid price
        uint256 minPercentageToAsk; // The maker's minimum % to receive from the sale
        uint256 nonce; // The maker's nonce
        address strategy; // LooksRare execution strategy
    }

    ILooksRareExchange public immutable marketplace;

    constructor(address _marketplace) {
        marketplace = ILooksRareExchange(_marketplace);
    }

    /**
     * @notice Execute LooksRare NFT sweeps in a single transaction
     * @dev The 1st argument tokenTransfers and the 4th argument extraData are not used
     * @param orders Orders to be executed by LooksRare
     * @param ordersExtraData Extra data for each order
     * @param recipient The address to receive the purchased NFTs
     * @param isAtomic Flag to enable atomic trades (all or nothing) or partial trades
     * @return Whether at least 1 out of N trades succeeded
     */
    function buyWithETH(
        TokenTransfer[] calldata,
        BasicOrder[] calldata orders,
        bytes[] calldata ordersExtraData,
        bytes memory,
        address recipient,
        bool isAtomic
    ) external payable override returns (bool) {
        if (recipient == address(0)) revert ZeroAddress();

        uint256 ordersLength = orders.length;
        if (ordersLength == 0 || ordersLength != ordersExtraData.length) revert InvalidOrderLength();

        uint256 executedCount;
        for (uint256 i; i < ordersLength; ) {
            BasicOrder memory order = orders[i];

            OrderExtraData memory orderExtraData = abi.decode(ordersExtraData[i], (OrderExtraData));

            OrderTypes.MakerOrder memory makerAsk;
            {
                makerAsk.isOrderAsk = true;
                makerAsk.signer = order.signer;
                makerAsk.collection = order.collection;
                makerAsk.tokenId = order.tokenIds[0];
                makerAsk.price = orderExtraData.makerAskPrice;
                makerAsk.amount = order.amounts[0];
                makerAsk.strategy = orderExtraData.strategy;
                makerAsk.nonce = orderExtraData.nonce;
                makerAsk.minPercentageToAsk = orderExtraData.minPercentageToAsk;
                makerAsk.currency = order.currency;
                makerAsk.startTime = order.startTime;
                makerAsk.endTime = order.endTime;

                (bytes32 r, bytes32 s, uint8 v) = _splitSignature(order.signature);
                makerAsk.v = v;
                makerAsk.r = r;
                makerAsk.s = s;
            }

            OrderTypes.TakerOrder memory takerBid;
            {
                takerBid.isOrderAsk = false;
                takerBid.taker = address(this);
                takerBid.price = order.price;
                takerBid.tokenId = order.tokenIds[0];
                takerBid.minPercentageToAsk = orderExtraData.minPercentageToAsk;
            }

            if (_executeSingleOrder(takerBid, makerAsk, recipient, order.collectionType, isAtomic)) {
                executedCount += 1;
            }

            unchecked {
                ++i;
            }
        }

        _returnETHIfAny();

        return executedCount > 0;
    }

    function _executeSingleOrder(
        OrderTypes.TakerOrder memory takerBid,
        OrderTypes.MakerOrder memory makerAsk,
        address recipient,
        CollectionType collectionType,
        bool isAtomic
    ) private returns (bool executed) {
        if (isAtomic) {
            marketplace.matchAskWithTakerBidUsingETHAndWETH{value: takerBid.price}(takerBid, makerAsk);
            _transferTokenToRecipient(
                collectionType,
                recipient,
                makerAsk.collection,
                makerAsk.tokenId,
                makerAsk.amount
            );
            executed = true;
        } else {
            try marketplace.matchAskWithTakerBidUsingETHAndWETH{value: takerBid.price}(takerBid, makerAsk) {
                _transferTokenToRecipient(
                    collectionType,
                    recipient,
                    makerAsk.collection,
                    makerAsk.tokenId,
                    makerAsk.amount
                );
                executed = true;
            } catch {}
        }
    }
}
