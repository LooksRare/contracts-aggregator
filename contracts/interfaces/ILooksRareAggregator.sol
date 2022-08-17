// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import {BasicOrder} from "../libraries/OrderStructs.sol";

interface ILooksRareAggregator {
    struct TradeData {
        address proxy; // The marketplace proxy's address
        bytes4 selector; // The marketplace proxy's function selector
        uint256 value; // The amount of ETH passed to the proxy during the function call
        BasicOrder[] orders; // Orders to be executed by the marketplace
        bytes[] ordersExtraData; // Extra data for each order, specific for each marketplace
        bytes extraData; // Extra data specific for each marketplace
    }

    /// @notice Emitted when a marketplace proxy's function is enabled.
    /// @param proxy The marketplace proxy's address
    /// @param selector The marketplace proxy's function selector
    event FunctionAdded(address indexed proxy, bytes4 selector);

    /// @notice Emitted when a marketplace proxy's function is disabled.
    /// @param proxy The marketplace proxy's address
    /// @param selector The marketplace proxy's function selector
    event FunctionRemoved(address indexed proxy, bytes4 selector);

    /// @notice Emitted when buyWithETH is complete
    /// @param sweeper The address that submitted the transaction
    /// @param tradeCount Total trade count
    /// @param successCount Successful trade count (if only 1 out of N trades in
    ///                     an order succeeds, it is consider successful)
    event Sweep(address indexed sweeper, uint256 tradeCount, uint256 successCount);

    error InvalidFunction();
    error TradeExecutionFailed();
}
