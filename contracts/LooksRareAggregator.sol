// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import {OwnableTwoSteps} from "@looksrare/contracts-libs/contracts/OwnableTwoSteps.sol";
import {LooksRareProxy} from "./proxies/LooksRareProxy.sol";
import {BasicOrder} from "./libraries/OrderStructs.sol";
import {LowLevelETH} from "./lowLevelCallers/LowLevelETH.sol";

/**
 * @title LooksRareAggregator
 * @notice This contract allows NFT sweepers to buy NFTs from different marketplaces
 *         by passing high-level structs + low-level bytes as calldata.
 * @author LooksRare protocol team (👀,💎)
 */
contract LooksRareAggregator is OwnableTwoSteps, LowLevelETH {
    struct TradeData {
        address proxy; // The marketplace proxy's address
        bytes4 selector; // The marketplace proxy's function selector
        uint256 value; // The amount of ETH passed to the proxy during the function call
        BasicOrder[] orders; // An array of orders to be executed by the marketplace
        bytes[] ordersExtraData; // Extra data per order, specific for each marketplace
        bytes extraData; // Extra data specific for each marketplace
    }

    mapping(address => mapping(bytes4 => bool)) private proxyFunctionSelectors;

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

    /// @notice Execute NFT sweeps in different marketplaces in a single transaction
    /// @param tradeData Data object to be passed downstream to each marketplace's proxy for execution
    /// @param isAtomic Flag to enable atomic trades (all or nothing) or partial trades
    function buyWithETH(TradeData[] calldata tradeData, bool isAtomic) external payable {
        uint256 successCount;
        for (uint256 i; i < tradeData.length; ) {
            address proxy = tradeData[i].proxy;
            bytes4 selector = tradeData[i].selector;
            if (!proxyFunctionSelectors[proxy][selector]) revert InvalidFunction();

            (bool success, bytes memory returnData) = proxy.call{value: tradeData[i].value}(
                abi.encodeWithSelector(
                    selector,
                    tradeData[i].orders,
                    tradeData[i].ordersExtraData,
                    tradeData[i].extraData,
                    isAtomic
                )
            );

            if (success) {
                bool someExecuted = abi.decode(returnData, (bool));
                if (someExecuted) successCount += 1;
            } else {
                if (isAtomic) {
                    if (returnData.length > 0) {
                        assembly {
                            let returnDataSize := mload(returnData)
                            revert(add(32, returnData), returnDataSize)
                        }
                    } else {
                        revert TradeExecutionFailed();
                    }
                }
            }

            unchecked {
                ++i;
            }
        }

        _returnETHIfAny(msg.sender);

        emit Sweep(msg.sender, tradeData.length, successCount);
    }

    /// @notice Enable calling the specified proxy's trade function
    /// @dev Must be called by the current owner
    /// @param proxy The marketplace proxy's address
    /// @param selector The marketplace proxy's function selector
    function addFunction(address proxy, bytes4 selector) external onlyOwner {
        proxyFunctionSelectors[proxy][selector] = true;
        emit FunctionAdded(proxy, selector);
    }

    /// @notice Disable calling the specified proxy's trade function
    /// @dev Must be called by the current owner
    /// @param proxy The marketplace proxy's address
    /// @param selector The marketplace proxy's function selector
    function removeFunction(address proxy, bytes4 selector) external onlyOwner {
        delete proxyFunctionSelectors[proxy][selector];
        emit FunctionRemoved(proxy, selector);
    }

    /// @param proxy The marketplace proxy's address
    /// @param selector The marketplace proxy's function selector
    /// @return Whether the marketplace proxy's function can be called from the aggregator
    function supportsProxyFunction(address proxy, bytes4 selector) external view returns (bool) {
        return proxyFunctionSelectors[proxy][selector];
    }
}
