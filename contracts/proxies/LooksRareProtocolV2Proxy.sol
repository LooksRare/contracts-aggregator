// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// Interfaces
import {ILooksRareProtocolV2} from "../interfaces/ILooksRareProtocolV2.sol";
import {IProxy} from "../interfaces/IProxy.sol";

// Libraries
import {OrderStructs} from "../libraries/looksrare-v2/OrderStructs.sol";
import {BasicOrder} from "../libraries/OrderStructs.sol";

// Shared errors
import {InvalidOrderLength} from "../libraries/SharedErrors.sol";

/**
 * @title LooksRareProtocolV2Proxy
 * @notice This contract allows NFT sweepers to batch buy NFTs from LooksRare protocol v2
 *         by passing high-level structs + low-level bytes as calldata.
 * @author LooksRare protocol team (👀,💎)
 */
contract LooksRareProtocolV2Proxy is IProxy {
    /**
     * @notice This struct contains the fields specific to the overall execution of all orders.
     * @param sameCurrency Whether all trades have the same currency
     */
    struct ExtraData {
        address affiliate;
    }

    /**
     * @notice This struct contains the fields specific to the execution of each single order.
     * @param merkleTree Merkle tree struct
     * @param askNonce Ask nonce of the maker ask order
     * @param subsetNonce Subset nonce of the maker ask order
     * @param strategyId Strategy id
     * @param orderNonce Order nonce of the maker ask order
     * @param minMakerAskPrice Minimum maker ask price
     * @param additionalParametersTakerBid Additional parameters for taker bid orde
     * @param additionalParametersMakerAsk Additional parameters for maker ask order
     */
    struct OrderExtraData {
        OrderStructs.MerkleTree merkleTree;
        uint256 askNonce;
        uint256 subsetNonce;
        uint256 strategyId;
        uint256 orderNonce;
        uint256 minMakerAskPrice;
        bytes additionalParametersTakerBid;
        bytes additionalParametersMakerAsk;
    }

    /**
     * @notice Marketplace (LooksRare v2 protocol).
     */
    ILooksRareProtocolV2 public immutable marketplace;

    /**
     * @notice Aggregator address.
     */
    address public immutable aggregator;

    /**
     * @param _marketplace LooksRareProtocol's address
     * @param _aggregator LooksRareAggregator's address
     */
    constructor(address _marketplace, address _aggregator) {
        marketplace = ILooksRareProtocolV2(_marketplace);
        aggregator = _aggregator;
    }

    /**
     * @notice This function allows to execute LooksRare NFT sweeps in a single transaction.
     * @param orders Orders to be executed by LooksRare
     * @param ordersExtraData Extra data specific to each order
     * @param extraData Extra data for the overall execution that is shared for all orders (i.e. affiliate)
     * @param recipient The address to receive the purchased NFTs
     * @param isAtomic Flag to enable atomic trades (all or nothing) or partial filling
     */
    function execute(
        BasicOrder[] calldata orders,
        bytes[] calldata ordersExtraData,
        bytes memory extraData,
        address recipient,
        bool isAtomic
    ) external payable override {
        if (address(this) != aggregator) {
            revert InvalidCaller();
        }

        uint256 ordersLength = orders.length;

        if (ordersLength == 0 || ordersLength != ordersExtraData.length) {
            revert InvalidOrderLength();
        }

        // Extract the affiliate address
        address affiliate = abi.decode(extraData, (address));

        for (uint256 i; i < ordersLength; ) {
            uint256 numberConsecutiveOrders;
            address currency = orders[i].currency;

            // Count how many orders to execute
            while (i != ordersLength - 1 || currency != orders[i + 1].currency) {
                unchecked {
                    ++numberConsecutiveOrders;
                    ++i;
                }
            }

            // Initialize structs
            OrderStructs.TakerBid[] memory takerBids = new OrderStructs.TakerBid[](numberConsecutiveOrders);
            OrderStructs.MakerAsk[] memory makerAsks = new OrderStructs.MakerAsk[](numberConsecutiveOrders);
            OrderStructs.MerkleTree[] memory merkleTrees = new OrderStructs.MerkleTree[](numberConsecutiveOrders);
            bytes[] memory makerSignatures = new bytes[](numberConsecutiveOrders);

            // Initialize ethValue
            uint256 ethValue;

            // Loop again over each consecutive order
            for (uint256 k = 0; k < numberConsecutiveOrders; ) {
                OrderExtraData memory orderExtraData = abi.decode(
                    ordersExtraData[i + k - numberConsecutiveOrders],
                    (OrderExtraData)
                );
                BasicOrder memory basicOrder = orders[i + k - numberConsecutiveOrders];

                // Fill taker bid parameters
                takerBids[k].recipient = recipient;
                takerBids[k].maxPrice = basicOrder.price;
                takerBids[k].itemIds = basicOrder.tokenIds;
                takerBids[k].amounts = basicOrder.amounts;
                takerBids[k].additionalParameters = orderExtraData.additionalParametersTakerBid;

                // Fill maker ask parameters
                makerAsks[k].askNonce = orderExtraData.askNonce;
                makerAsks[k].subsetNonce = orderExtraData.subsetNonce;
                makerAsks[k].strategyId = orderExtraData.strategyId;
                makerAsks[k].assetType = uint256(basicOrder.collectionType);
                makerAsks[k].orderNonce = orderExtraData.orderNonce;
                makerAsks[k].collection = basicOrder.collection;
                makerAsks[k].currency = basicOrder.currency;
                makerAsks[k].signer = basicOrder.signer;
                makerAsks[k].startTime = basicOrder.startTime;
                makerAsks[k].endTime = basicOrder.endTime;
                makerAsks[k].minPrice = orderExtraData.minMakerAskPrice;
                makerAsks[k].itemIds = basicOrder.tokenIds;
                makerAsks[k].amounts = basicOrder.amounts;
                makerAsks[k].additionalParameters = orderExtraData.additionalParametersMakerAsk;

                // Maker signatures
                makerSignatures[k] = basicOrder.signature;

                // Merkle tree
                merkleTrees[k] = orderExtraData.merkleTree;

                if (currency == address(0)) {
                    ethValue += basicOrder.price;
                }

                unchecked {
                    ++k;
                }
            }

            // Execute taker bid orders
            if (numberConsecutiveOrders == 1) {
                if (isAtomic) {
                    marketplace.executeTakerBid{value: ethValue}(
                        takerBids[0],
                        makerAsks[0],
                        makerSignatures[0],
                        merkleTrees[0],
                        affiliate
                    );
                } else {
                    try
                        marketplace.executeTakerBid{value: ethValue}(
                            takerBids[0],
                            makerAsks[0],
                            makerSignatures[0],
                            merkleTrees[0],
                            affiliate
                        )
                    {} catch {}
                }
            } else {
                marketplace.executeMultipleTakerBids{value: ethValue}(
                    takerBids,
                    makerAsks,
                    makerSignatures,
                    merkleTrees,
                    affiliate,
                    isAtomic
                );
            }
        }
    }
}
