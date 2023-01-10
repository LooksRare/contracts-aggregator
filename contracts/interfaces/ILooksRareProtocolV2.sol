// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {OrderStructs} from "../libraries/looksrare-v2/OrderStructs.sol";

interface ILooksRareProtocolV2 {
    /**
     * @notice This function allows a user to execute a taker bid (against a maker ask).
     * @param takerBid Taker bid struct
     * @param makerAsk Maker ask struct
     * @param makerSignature Maker signature
     * @param merkleTree Merkle tree struct (if the signature contains multiple maker orders)
     * @param affiliate Affiliate address
     */
    function executeTakerBid(
        OrderStructs.TakerBid calldata takerBid,
        OrderStructs.MakerAsk calldata makerAsk,
        bytes calldata makerSignature,
        OrderStructs.MerkleTree calldata merkleTree,
        address affiliate
    ) external payable;

    /**
     * @notice This function allows a user to batch buy with an array of taker bids (against an array of maker asks).
     * @param takerBids Array of taker bid structs
     * @param makerAsks Array of maker ask structs
     * @param makerSignatures Array of maker signatures
     * @param merkleTrees Array of merkle tree structs if the signature contains multiple maker orders
     * @param affiliate Affiliate address
     * @param isAtomic Whether the execution should be atomic i.e. whether it should revert if 1 or more transactions fail
     */
    function executeMultipleTakerBids(
        OrderStructs.TakerBid[] calldata takerBids,
        OrderStructs.MakerAsk[] calldata makerAsks,
        bytes[] calldata makerSignatures,
        OrderStructs.MerkleTree[] calldata merkleTrees,
        address affiliate,
        bool isAtomic
    ) external payable;
}
