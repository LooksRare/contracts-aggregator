// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import {BasicOrder} from "../libraries/OrderStructs.sol";

interface IProxy {
    error InvalidOrderLength();
    error InvalidRecipient();
    error ZeroAddress();

    function buyWithETH(
        BasicOrder[] calldata orders,
        bytes[] calldata ordersExtraData,
        bytes calldata
    ) external payable;
}
