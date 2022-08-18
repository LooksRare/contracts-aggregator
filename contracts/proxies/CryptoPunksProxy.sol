// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import {BasicOrder} from "../libraries/OrderStructs.sol";
import {ICryptoPunks} from "../interfaces/ICryptoPunks.sol";
import {IProxy} from "./IProxy.sol";
import {LowLevelETH} from "../lowLevelCallers/LowLevelETH.sol";

/**
 * @title CryptoPunksProxy
 * @notice This contract allows NFT sweepers to batch buy NFTs from CryptoPunks
 *         by passing high-level structs + low-level bytes as calldata.
 * @author LooksRare protocol team (👀,💎)
 */
contract CryptoPunksProxy is IProxy, LowLevelETH {
    ICryptoPunks public cryptopunks;

    constructor(address _cryptopunks) {
        cryptopunks = ICryptoPunks(_cryptopunks);
    }

    /// @notice Execute CryptoPunks NFT sweeps in a single transaction
    /// @dev Only the 1st argument orders and the 4th argument isAtomic are used
    /// @param orders Orders to be executed by CryptoPunks
    /// @param isAtomic Flag to enable atomic trades (all or nothing) or partial trades
    /// @return Whether at least 1 out of N trades succeeded
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
                cryptopunks.buyPunk{value: orders[i].price}(punkId);
                cryptopunks.transferPunk(orders[i].recipient, punkId);
                executedCount += 1;
            } else {
                try cryptopunks.buyPunk{value: orders[i].price}(punkId) {
                    cryptopunks.transferPunk(orders[i].recipient, punkId);
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
