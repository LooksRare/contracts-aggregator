// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import {BasicOrder, TokenTransfer} from "../libraries/OrderStructs.sol";
import {ICryptoPunks} from "../interfaces/ICryptoPunks.sol";
import {IProxy} from "./IProxy.sol";
import {TokenRescuer} from "../TokenRescuer.sol";

/**
 * @title CryptoPunksProxy
 * @notice This contract allows NFT sweepers to batch buy NFTs from CryptoPunks
 *         by passing high-level structs + low-level bytes as calldata.
 * @author LooksRare protocol team (👀,💎)
 */
contract CryptoPunksProxy is IProxy, TokenRescuer {
    ICryptoPunks public immutable cryptopunks;

    constructor(address _cryptopunks) {
        cryptopunks = ICryptoPunks(_cryptopunks);
    }

    /**
     * @notice Execute CryptoPunks NFT sweeps in a single transaction
     * @dev Only "orders" and the "isAtomic" are used
     * @param orders Orders to be executed by CryptoPunks
     * @param recipient The address to receive the purchased NFTs
     * @param isAtomic Flag to enable atomic trades (all or nothing) or partial trades
     * @return Whether at least 1 out of N trades succeeded
     */
    function execute(
        TokenTransfer[] calldata,
        BasicOrder[] calldata orders,
        bytes[] calldata,
        bytes memory,
        address recipient,
        bool isAtomic
    ) external payable override returns (bool) {
        if (recipient == address(0)) revert ZeroAddress();
        uint256 ordersLength = orders.length;
        if (ordersLength == 0) revert InvalidOrderLength();

        uint256 executedCount;
        for (uint256 i; i < ordersLength; ) {
            uint256 punkId = orders[i].tokenIds[0];

            if (isAtomic) {
                cryptopunks.buyPunk{value: orders[i].price}(punkId);
                cryptopunks.transferPunk(recipient, punkId);
                executedCount += 1;
            } else {
                try cryptopunks.buyPunk{value: orders[i].price}(punkId) {
                    cryptopunks.transferPunk(recipient, punkId);
                    executedCount += 1;
                } catch {}
            }

            unchecked {
                ++i;
            }
        }

        _returnETHIfAny();

        return executedCount > 0;
    }
}
