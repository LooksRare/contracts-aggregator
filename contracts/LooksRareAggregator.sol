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
    struct Proxy {
        bool supportsERC20Orders;
        mapping(bytes4 => bool) functionSelectors;
    }
    mapping(address => Proxy) private _proxies;

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
            if (!_proxies[tradeData[i].proxy].functionSelectors[tradeData[i].selector]) revert InvalidFunction();

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
     * @inheritdoc ILooksRareAggregator
     */
    function pullERC20Tokens(
        address buyer,
        address currency,
        uint256 amount
    ) external override {
        if (!_proxies[msg.sender].supportsERC20Orders) revert UnauthorizedToPullTokens();
        _executeERC20Transfer(currency, buyer, msg.sender, amount);
    }

    /**
     * @notice Enable calling the specified proxy's trade function
     * @dev Must be called by the current owner
     * @param proxy The marketplace proxy's address
     * @param selector The marketplace proxy's function selector
     */
    function addFunction(address proxy, bytes4 selector) external onlyOwner {
        _proxies[proxy].functionSelectors[selector] = true;
        emit FunctionAdded(proxy, selector);
    }

    /**
     * @notice Disable calling the specified proxy's trade function
     * @dev Must be called by the current owner
     * @param proxy The marketplace proxy's address
     * @param selector The marketplace proxy's function selector
     */
    function removeFunction(address proxy, bytes4 selector) external onlyOwner {
        delete _proxies[proxy].functionSelectors[selector];
        emit FunctionRemoved(proxy, selector);
    }

    /**
     * @notice Toggle a marketplace proxy's supports ERC-20 tokens orders flag
     * @dev Must be called by the current owner
     * @param proxy The marketplace proxy's address
     * @param isSupported Whether the marketplace supports orders paid with ERC-20 tokens
     */
    function setSupportsERC20Orders(address proxy, bool isSupported) external onlyOwner {
        _proxies[proxy].supportsERC20Orders = isSupported;
        emit SupportsERC20OrdersUpdated(proxy, isSupported);
    }

    /**
     * @param proxy The marketplace proxy's address
     * @param selector The marketplace proxy's function selector
     * @return Whether the marketplace proxy's function can be called from the aggregator
     */
    function supportsProxyFunction(address proxy, bytes4 selector) external view returns (bool) {
        return _proxies[proxy].functionSelectors[selector];
    }

    /**
     * @param proxy The marketplace proxy's address
     * @return Whether the marketplace proxy supports ERC-20 tokens orders
     */
    function supportsERC20Orders(address proxy) external view returns (bool) {
        return _proxies[proxy].supportsERC20Orders;
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
