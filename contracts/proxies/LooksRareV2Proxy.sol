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
 * @title LooksRareV2Proxy
 * @notice This contract allows NFT sweepers to batch buy NFTs from LooksRare protocol v2
 *         by passing high-level structs + low-level bytes as calldata.
 * @author LooksRare protocol team (👀,💎)
 */
contract LooksRareV2Proxy is IProxy {
    /**
     * @notice This struct contains the fields specific to the overall execution of all orders.
     * @param affiliate Address of the affiliate
     */
    struct ExtraData {
        address affiliate;
    }

    /**
     * @notice This struct contains the fields specific to the execution of each single order.
     * @param merkleTree Merkle tree struct
     * @param askNonce Ask nonce of the maker ask order
     * @param subsetNonce Subset nonce of the maker ask order
     * @param orderNonce Order nonce of the maker ask order
     * @param strategyId Strategy id
     * @param minMakerAskPrice Minimum maker ask price
     * @param takerBidAdditionalParameters Additional parameters for taker bid order
     * @param makerAskAdditionalParameters Additional parameters for maker ask order
     */
    struct OrderExtraData {
        OrderStructs.MerkleTree merkleTree;
        uint256 askNonce;
        uint256 subsetNonce;
        uint256 orderNonce;
        uint256 strategyId;
        uint256 minMakerAskPrice;
        bytes takerBidAdditionalParameters;
        bytes makerAskAdditionalParameters;
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
     * @notice This function executes LooksRare NFT sweeps in a single transaction.
     * @param orders Orders to be executed by LooksRare
     * @param ordersExtraData Extra data specific to each order
     * @param extraData Extra data for the overall execution that is shared for all orders (i.e. affiliate)
     * @param recipient The address to receive the purchased NFTs
     * @param isAtomic Flag to enable atomic trades (all or nothing) or partial filling
     */
    function execute(
        BasicOrder[] calldata orders,
        bytes[] calldata ordersExtraData,
        bytes calldata extraData,
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
            uint256 numberOfConsecutiveOrders = 1;

            {
                address currency = orders[i].currency;

                // Count how many orders to execute
                while (i != ordersLength - 1 && currency == orders[i + 1].currency) {
                    unchecked {
                        ++numberOfConsecutiveOrders;
                        ++i;
                    }
                }
            }

            // Initialize structs
            OrderStructs.TakerBid[] memory takerBids = new OrderStructs.TakerBid[](numberOfConsecutiveOrders);
            OrderStructs.MakerAsk[] memory makerAsks = new OrderStructs.MakerAsk[](numberOfConsecutiveOrders);
            OrderStructs.MerkleTree[] memory merkleTrees = new OrderStructs.MerkleTree[](numberOfConsecutiveOrders);
            bytes[] memory makerSignatures = new bytes[](numberOfConsecutiveOrders);

            // Initialize ethValue
            uint256 ethValue;

            /**
             * @dev This loop rewinds from the current pointer back to the start of the subset of orders sharing the same currency.
             *      Then, it loops through the subset with a new iterator (k).
             */
            for (uint256 k = 1; k <= numberOfConsecutiveOrders; ) {
                /**
                 * @dev i = iterator in the main loop of all orders to be processed with the proxy
                 *      k = iterator in the current loop of all orders sharing the same currency
                 *      numberOfConsecutiveOrders = next count of maker orders that should be executed in a batch with v2
                 *      (i + 1 - numberOfConsecutiveOrders) = first maker ask order position in the array that was not executed
                 *      For instance, if there are 4 orders with the first one denominated in USDC and the next 3 being in ETH.
                 *      1 - USDC
                 *      i = 0, numberOfConsecutiveOrders = 1, k = 1
                 *      --> i + k - numberOfConsecutiveOrders = 0;
                 *      2 - ETH
                 *      i = 3, numberOfConsecutiveOrders = 3, k = 1/2/3
                 *      i + k - numberOfConsecutiveOrders = 1/2/3
                 */
                OrderExtraData memory orderExtraData = abi.decode(
                    ordersExtraData[i - numberOfConsecutiveOrders + k],
                    (OrderExtraData)
                );

                BasicOrder calldata basicOrder = orders[i - numberOfConsecutiveOrders + k];

                // Fill taker bid parameters
                takerBids[k].recipient = recipient;
                takerBids[k].maxPrice = basicOrder.price;
                takerBids[k].itemIds = basicOrder.tokenIds;
                takerBids[k].amounts = basicOrder.amounts;
                takerBids[k].additionalParameters = orderExtraData.takerBidAdditionalParameters;

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
                makerAsks[k].additionalParameters = orderExtraData.makerAskAdditionalParameters;

                // Maker signatures
                makerSignatures[k] = basicOrder.signature;

                // Merkle tree
                merkleTrees[k] = orderExtraData.merkleTree;

                if (basicOrder.currency == address(0)) {
                    // IR gas savings
                    ethValue = ethValue + basicOrder.price;
                }

                unchecked {
                    ++k;
                }
            }

            // Execute taker bid orders
            if (numberOfConsecutiveOrders == 1) {
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

            unchecked {
                ++i;
            }
        }
    }
}
