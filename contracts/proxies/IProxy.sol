// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import {BasicOrder, TokenTransfer} from "../libraries/OrderStructs.sol";

interface IProxy {
    error InvalidOrderLength();
    error ZeroAddress();

    /**
     * @notice Execute NFT sweeps in a single transaction
     * @param tokenTransfers Aggregated ERC-20 token transfers for all orders
     * @param orders Orders to be executed
     * @param ordersExtraData Extra data for each order
     * @param extraData Extra data for the whole transaction
     * @param buyer The address to pull ERC-20 tokens from (only if there are tokenTransfers)
     * @param recipient The address to receive the purchased NFTs
     * @param isAtomic Flag to enable atomic trades (all or nothing) or partial trades
     */
    function execute(
        TokenTransfer[] calldata tokenTransfers,
        BasicOrder[] calldata orders,
        bytes[] calldata ordersExtraData,
        bytes calldata extraData,
        address buyer,
        address recipient,
        bool isAtomic
    ) external payable returns (bool);
}
