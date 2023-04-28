// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IReservoirRouter {
    struct ExecutionInfo {
        address module;
        bytes data;
        uint256 value;
    }

    function execute(ExecutionInfo[] calldata executionInfos) external payable;
}
