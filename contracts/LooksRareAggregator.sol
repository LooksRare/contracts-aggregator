// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import {OwnableTwoSteps} from "@looksrare/contracts-libs/contracts/OwnableTwoSteps.sol";
import {LooksRareV2Proxy} from "./proxies/LooksRareV2Proxy.sol";
import {BasicOrder} from "./libraries/OrderStructs.sol";
import {LowLevelETH} from "./lowLevelCallers/LowLevelETH.sol";

import "hardhat/console.sol";

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

    function buyWithETH(TradeData[] calldata tradeData) external payable {
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
                    tradeData[i].extraData
                )
            );

            console.logBytes(returnData);

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