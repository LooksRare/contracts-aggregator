// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

interface IX2Y2Run {
    function run1()
        external
        returns (
            // Market.Order memory order,
            // Market.SettleShared memory shared,
            // Market.SettleDetail memory detail
            uint256
        );
}
