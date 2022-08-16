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
        address proxy;
        bytes4 selector;
        uint256 value;
        BasicOrder[] orders;
        bytes[] ordersExtraData;
        bytes extraData;
    }

    mapping(address => mapping(bytes4 => bool)) private proxyFunctionSelectors;

    event FunctionAdded(address indexed proxy, bytes4 selector);
    event FunctionRemoved(address indexed proxy, bytes4 selector);

    error InvalidFunction();
    error TradeExecutionFailed();

    function buyWithETH(TradeData[] calldata tradeData, bool isAtomic) external payable {
        uint256 tradeCount = tradeData.length;
        for (uint256 i; i < tradeCount; ) {
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

            if (!success) {
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
    }

    function addFunction(address proxy, bytes4 selector) external onlyOwner {
        proxyFunctionSelectors[proxy][selector] = true;
        emit FunctionAdded(proxy, selector);
    }

    function removeFunction(address proxy, bytes4 selector) external onlyOwner {
        delete proxyFunctionSelectors[proxy][selector];
        emit FunctionRemoved(proxy, selector);
    }

    function supportsProxyFunction(address proxy, bytes4 selector) external view returns (bool) {
        return proxyFunctionSelectors[proxy][selector];
    }
}
