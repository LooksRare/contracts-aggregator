// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import {BasicOrder, TokenTransfer} from "../libraries/OrderStructs.sol";
import {ICryptoPunks} from "../interfaces/ICryptoPunks.sol";
import {IProxy} from "./IProxy.sol";
import {TokenLogic} from "../TokenLogic.sol";

/**
 * @title CryptoPunksProxy
 * @notice This contract allows NFT sweepers to batch buy NFTs from CryptoPunks
 *         by passing high-level structs + low-level bytes as calldata.
 * @author LooksRare protocol team (👀,💎)
 */
contract CryptoPunksProxy is IProxy, TokenLogic {
    ICryptoPunks public immutable marketplace;
    uint256 public feeBp;
    address public feeRecipient;

    /**
     * @param _marketplace CryptoPunks' address
     */
    constructor(address _marketplace) {
        marketplace = ICryptoPunks(_marketplace);
    }

    /**
     * @notice Execute CryptoPunks NFT sweeps in a single transaction
     * @dev Only orders, recipient and isAtomic are used
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
        uint256 ordersLength = orders.length;
        if (ordersLength == 0) revert InvalidOrderLength();

        uint256 executedCount;
        for (uint256 i; i < ordersLength; ) {
            uint256 punkId = orders[i].tokenIds[0];

            if (isAtomic) {
                marketplace.buyPunk{value: orders[i].price}(punkId);
                marketplace.transferPunk(recipient, punkId);
                executedCount += 1;
            } else {
                try marketplace.buyPunk{value: orders[i].price}(punkId) {
                    marketplace.transferPunk(recipient, punkId);
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

    /**
     * @inheritdoc IProxy
     */
    function setFeeBp(uint256 _feeBp) external override onlyOwner {
        if (_feeBp > 10000) revert FeeTooHigh();
        feeBp = _feeBp;
        emit FeeUpdated(_feeBp);
    }

    /**
     * @inheritdoc IProxy
     */
    function setFeeRecipient(address _feeRecipient) external override onlyOwner {
        feeRecipient = _feeRecipient;
        emit FeeRecipientUpdated(_feeRecipient);
    }
}
