// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import {OwnableTwoSteps} from "@looksrare/contracts-libs/contracts/OwnableTwoSteps.sol";

import "hardhat/console.sol";

contract Aggregator is OwnableTwoSteps {
    struct TradeData {
        bytes data;
        uint256 value;
    }

    mapping(bytes4 => address) private tradeFunctions;

    event FunctionAdded(address indexed proxy, bytes4 selector);
    event FunctionRemoved(address indexed proxy, bytes4 selector);

    error InvalidFunction();

    function buyWithETH(TradeData[] calldata tradeData) external payable {
        uint256 tradeCount = tradeData.length;
        for (uint256 i; i < tradeCount; ) {
            bytes calldata data = tradeData[i].data;
            bytes4 selector;

            assembly {
                selector := calldataload(data.offset)
            }

            address proxy = tradeFunctions[selector];
            if (proxy == address(0)) revert InvalidFunction();

            (bool success, bytes memory returnData) = proxy.call{value: tradeData[i].value}(data);
            // proxy.call{value: tradeData[i].value}(data);

            if (!success) {
                if (returnData.length > 0) {
                    assembly {
                        let returnDataSize := mload(returnData)
                        revert(add(32, returnData), returnDataSize)
                    }
                } else {}
            }

            unchecked {
                ++i;
            }
        }
    }

    function addFunction(bytes4 selector, address proxy) external onlyOwner {
        tradeFunctions[selector] = proxy;
        emit FunctionAdded(proxy, selector);
    }

    function removeFunction(bytes4 selector) external onlyOwner {
        address proxy = tradeFunctions[selector];
        delete tradeFunctions[selector];
        emit FunctionRemoved(proxy, selector);
    }
}
