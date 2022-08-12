// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import {IX2Y2Run} from "../interfaces/IX2Y2Run.sol";
import {BasicOrder} from "../libraries/OrderStructs.sol";

contract X2Y2Proxy {
    // IX2Y2Run constant public MARKETPLACE = IX2Y2(0x74312363e45DCaBA76c59ec49a7Aa8A65a67EeD3);

    function buyWithETH(
        BasicOrder[] calldata orders,
        bytes[] calldata ordersExtraData,
        bytes calldata extraData
    ) external payable {}
}
