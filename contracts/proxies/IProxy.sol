// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import {BasicOrder} from "../libraries/OrderStructs.sol";

interface IProxy {
    error InvalidOrderLength();
    error InvalidRecipient();
    error ZeroAddress();

    /**
     * @notice Execute NFT sweeps in a single transaction
     * @param orders Orders to be executed
     * @param ordersExtraData Extra data for each order
     * @param extraData Extra data for the whole transaction
     * @param isAtomic Flag to enable atomic trades (all or nothing) or partial trades
     */
    function buyWithETH(
        BasicOrder[] calldata orders,
        bytes[] calldata ordersExtraData,
        bytes calldata extraData,
        bool isAtomic
    ) external payable returns (bool);
}
