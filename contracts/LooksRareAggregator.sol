// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import {OwnableTwoSteps} from "@looksrare/contracts-libs/contracts/OwnableTwoSteps.sol";
import {LooksRareV2Proxy} from "./proxies/LooksRareV2Proxy.sol";
import {BasicOrder} from "./libraries/OrderStructs.sol";

import "hardhat/console.sol";

contract LooksRareAggregator is OwnableTwoSteps {
    // struct SeaportRecipient {
    //   address recipient;
    //   uint256 amount;
    // }

    // should item type be calculated using IERC165?
    // struct SeaportData {
    //   uint8 orderType;
    //   address zone;
    //   bytes32 zoneHash;
    //   uint256 salt;
    //   bytes32 conduitKey;
    //   SeaportRecipient[] recipients;
    // }

    struct TradeData {
        address proxy;
        bytes4 selector;
        uint256 value;
        BasicOrder[] orders;
        bytes[] extraData;
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
                abi.encodeWithSelector(selector, tradeData[i].orders, tradeData[i].extraData)
            );

            unchecked {
                ++i;
            }
        }
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
