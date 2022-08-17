// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "../libraries/x2y2/MarketConsts.sol";

interface IX2Y2Run {
    function run(Market.RunInput memory input) external payable;
}
