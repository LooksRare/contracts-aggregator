// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import {BasicOrder} from "../libraries/OrderStructs.sol";
import {ICryptoPunks} from "../interfaces/ICryptoPunks.sol";
import {IProxy} from "./IProxy.sol";
import {LowLevelETH} from "../lowLevelCallers/LowLevelETH.sol";

contract CryptoPunksProxy is IProxy, LowLevelETH {
    ICryptoPunks constant CRYPTOPUNKS = ICryptoPunks(0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB);

    function buyWithETH(
        BasicOrder[] calldata orders,
        bytes[] calldata,
        bytes memory,
        bool isAtomic
    ) external payable override returns (bool) {
        uint256 ordersLength = orders.length;
        if (ordersLength == 0) revert InvalidOrderLength();

        uint256 executedCount;
        for (uint256 i; i < ordersLength; ) {
            if (orders[i].recipient == address(0)) revert ZeroAddress();

            uint256 punkId = orders[i].tokenIds[0];

            if (isAtomic) {
                CRYPTOPUNKS.buyPunk{value: orders[i].price}(punkId);
                CRYPTOPUNKS.transferPunk(orders[i].recipient, punkId);
                executedCount += 1;
            } else {
                try CRYPTOPUNKS.buyPunk{value: orders[i].price}(punkId) {
                    CRYPTOPUNKS.transferPunk(orders[i].recipient, punkId);
                    executedCount += 1;
                } catch {}
            }

            unchecked {
                ++i;
            }
        }

        _returnETHIfAny(tx.origin);

        return executedCount > 0;
    }
}
