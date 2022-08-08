// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import {OwnableTwoSteps} from "@looksrare/contracts-libs/contracts/OwnableTwoSteps.sol";

import "hardhat/console.sol";

contract Aggregator is OwnableTwoSteps {
    struct TradeData {
        address proxy;
        bytes data;
        uint256 value;
    }

    mapping(address => mapping(bytes4 => bool)) private proxyFunctionSelectors;

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

            address proxy = tradeData[i].proxy;
            if (!proxyFunctionSelectors[proxy][selector]) revert InvalidFunction();

            (bool success, bytes memory returnData) = proxy.call{value: tradeData[i].value}(data);
            // proxy.call{value: tradeData[i].value}(data);

            console.log("We have called Seaport");

            if (!success) {
                console.log("And it failed");
                if (returnData.length > 0) {
                    console.log("And there is return data");
                    console.logBytes(returnData);
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

    function addFunction(address proxy, bytes4 selector) external onlyOwner {
        proxyFunctionSelectors[proxy][selector] = true;
        emit FunctionAdded(proxy, selector);
    }

    function removeFunction(address proxy, bytes4 selector) external onlyOwner {
        delete proxyFunctionSelectors[proxy][selector];
        emit FunctionRemoved(proxy, selector);
    }
}
