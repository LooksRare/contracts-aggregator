// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import {LooksRareProxy} from "./proxies/LooksRareProxy.sol";
import {BasicOrder} from "./libraries/OrderStructs.sol";
import {TokenRescuer} from "./TokenRescuer.sol";
import {ILooksRareAggregator} from "./interfaces/ILooksRareAggregator.sol";

/**
 * @title LooksRareAggregator
 * @notice This contract allows NFT sweepers to buy NFTs from different marketplaces
 *         by passing high-level structs + low-level bytes as calldata.
 * @author LooksRare protocol team (👀,💎)
 */
contract LooksRareAggregator is TokenRescuer, ILooksRareAggregator {
    mapping(address => mapping(bytes4 => bool)) private _proxyFunctionSelectors;

    /**
     * @notice Execute NFT sweeps in different marketplaces in a single transaction
     * @param tradeData Data object to be passed downstream to each marketplace's proxy for execution
     * @param recipient The address to receive the purchased NFTs
     * @param isAtomic Flag to enable atomic trades (all or nothing) or partial trades
     */
    function execute(
        TradeData[] calldata tradeData,
        address recipient,
        bool isAtomic
    ) external payable {
        if (recipient == address(0)) revert ZeroAddress();
        if (tradeData.length == 0) revert InvalidOrderLength();

        uint256 successCount;
        for (uint256 i; i < tradeData.length; ) {
            if (!_proxyFunctionSelectors[tradeData[i].proxy][tradeData[i].selector]) revert InvalidFunction();

            (bool success, bytes memory returnData) = tradeData[i].proxy.call{value: tradeData[i].value}(
                _encodeCalldata(tradeData[i], recipient, isAtomic)
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

        _returnETHIfAny();

        emit Sweep(msg.sender, tradeData.length, successCount);
    }

    /**
     * @notice Enable calling the specified proxy's trade function
     * @dev Must be called by the current owner
     * @param proxy The marketplace proxy's address
     * @param selector The marketplace proxy's function selector
     */
    function addFunction(address proxy, bytes4 selector) external onlyOwner {
        _proxyFunctionSelectors[proxy][selector] = true;
        emit FunctionAdded(proxy, selector);
    }

    /**
     * @notice Disable calling the specified proxy's trade function
     * @dev Must be called by the current owner
     * @param proxy The marketplace proxy's address
     * @param selector The marketplace proxy's function selector
     */
    function removeFunction(address proxy, bytes4 selector) external onlyOwner {
        delete _proxyFunctionSelectors[proxy][selector];
        emit FunctionRemoved(proxy, selector);
    }

    /**
     * @param proxy The marketplace proxy's address
     * @param selector The marketplace proxy's function selector
     * @return Whether the marketplace proxy's function can be called from the aggregator
     */
    function supportsProxyFunction(address proxy, bytes4 selector) external view returns (bool) {
        return _proxyFunctionSelectors[proxy][selector];
    }

    function _encodeCalldata(
        TradeData calldata singleTradeData,
        address recipient,
        bool isAtomic
    ) private pure returns (bytes memory) {
        return
            abi.encodeWithSelector(
                singleTradeData.selector,
                singleTradeData.tokenTransfers,
                singleTradeData.orders,
                singleTradeData.ordersExtraData,
                singleTradeData.extraData,
                recipient,
                isAtomic
            );
    }

    receive() external payable {}
}
