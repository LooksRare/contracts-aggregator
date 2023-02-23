// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// Interfaces
import {ILooksRareProtocolV2} from "../interfaces/ILooksRareProtocolV2.sol";
import {IProxy} from "../interfaces/IProxy.sol";

// Libraries
import {Maker, Taker, MerkleTree, QuoteType} from "../libraries/looksrare-v2/OrderStructs.sol";
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
     * @dev A struct to merge the 5 calldata variables to prevent stack too deep error.
     * @param takerBids Taker bids to be used as function argument when calling LooksRare V2
     * @param makerAsks Maker asks to be used as function argument when calling LooksRare V2
     * @param makerSignatures Maker signatures to be used as function argument when calling LooksRare V2
     * @param merkleTrees Merkle trees to be used as function argument when calling LooksRare V2
     * @param ethValue The ETH value to be passed as msg.value when calling LooksRare V2
     */
    struct CalldataParams {
        Taker[] takerBids;
        Maker[] makerAsks;
        bytes[] makerSignatures;
        MerkleTree[] merkleTrees;
        uint256 ethValue;
    }

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
     * @param globalNonce Global ask nonce of the maker ask order
     * @param subsetNonce Subset nonce of the maker ask order
     * @param orderNonce Order nonce of the maker ask order
     * @param strategyId Strategy id
     * @param price Minimum maker ask price
     * @param takerBidAdditionalParameters Additional parameters for taker bid order
     * @param makerAskAdditionalParameters Additional parameters for maker ask order
     */
    struct OrderExtraData {
        MerkleTree merkleTree;
        uint256 globalNonce;
        uint256 subsetNonce;
        uint256 orderNonce;
        uint256 strategyId;
        uint256 price;
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

        for (uint256 i; i < ordersLength; ) {
            uint256 numberOfConsecutiveOrders = 1;

            address currency = orders[i].currency;

            // Count how many orders to execute
            while (i != ordersLength - 1 && currency == orders[i + 1].currency) {
                unchecked {
                    ++numberOfConsecutiveOrders;
                    ++i;
                }
            }

            // Initialize structs
            CalldataParams memory calldataParams;
            calldataParams.takerBids = new Taker[](numberOfConsecutiveOrders);
            calldataParams.makerAsks = new Maker[](numberOfConsecutiveOrders);
            calldataParams.makerSignatures = new bytes[](numberOfConsecutiveOrders);
            calldataParams.merkleTrees = new MerkleTree[](numberOfConsecutiveOrders);

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

                uint256 slicer = i + k - numberOfConsecutiveOrders;

                OrderExtraData memory orderExtraData = abi.decode(ordersExtraData[slicer], (OrderExtraData));

                // Fill taker bid parameters
                calldataParams.takerBids[k - 1].recipient = recipient;
                calldataParams.takerBids[k - 1].additionalParameters = orderExtraData.takerBidAdditionalParameters;

                // Fill maker ask parameters
                calldataParams.makerAsks[k - 1].quoteType = QuoteType.Ask;
                calldataParams.makerAsks[k - 1].globalNonce = orderExtraData.globalNonce;
                calldataParams.makerAsks[k - 1].orderNonce = orderExtraData.orderNonce;
                calldataParams.makerAsks[k - 1].subsetNonce = orderExtraData.subsetNonce;
                calldataParams.makerAsks[k - 1].strategyId = orderExtraData.strategyId;
                calldataParams.makerAsks[k - 1].price = orderExtraData.price;
                calldataParams.makerAsks[k - 1].additionalParameters = orderExtraData.makerAskAdditionalParameters;
                calldataParams.makerAsks[k - 1].collectionType = orders[slicer].collectionType;
                calldataParams.makerAsks[k - 1].collection = orders[slicer].collection;
                calldataParams.makerAsks[k - 1].currency = currency;
                calldataParams.makerAsks[k - 1].signer = orders[slicer].signer;
                calldataParams.makerAsks[k - 1].startTime = orders[slicer].startTime;
                calldataParams.makerAsks[k - 1].endTime = orders[slicer].endTime;
                calldataParams.makerAsks[k - 1].itemIds = orders[slicer].tokenIds;
                calldataParams.makerAsks[k - 1].amounts = orders[slicer].amounts;

                // Maker signature
                calldataParams.makerSignatures[k - 1] = orders[slicer].signature;

                // Merkle tree
                calldataParams.merkleTrees[k - 1] = orderExtraData.merkleTree;

                if (currency == address(0)) {
                    // IR gas savings
                    calldataParams.ethValue = calldataParams.ethValue + orders[slicer].price;
                }

                unchecked {
                    ++k;
                }
            }

            address affiliate = abi.decode(extraData, (address));

            // Execute taker bid orders
            if (numberOfConsecutiveOrders == 1) {
                if (isAtomic) {
                    marketplace.executeTakerBid{value: calldataParams.ethValue}(
                        calldataParams.takerBids[0],
                        calldataParams.makerAsks[0],
                        calldataParams.makerSignatures[0],
                        calldataParams.merkleTrees[0],
                        affiliate
                    );
                } else {
                    try
                        marketplace.executeTakerBid{value: calldataParams.ethValue}(
                            calldataParams.takerBids[0],
                            calldataParams.makerAsks[0],
                            calldataParams.makerSignatures[0],
                            calldataParams.merkleTrees[0],
                            affiliate
                        )
                    {} catch {}
                }
            } else {
                marketplace.executeMultipleTakerBids{value: calldataParams.ethValue}(
                    calldataParams.takerBids,
                    calldataParams.makerAsks,
                    calldataParams.makerSignatures,
                    calldataParams.merkleTrees,
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
