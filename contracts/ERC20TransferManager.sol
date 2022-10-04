// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {TokenTransfer} from "./libraries/OrderStructs.sol";
import {LowLevelERC20} from "@looksrare/contracts-libs/contracts/lowLevelCallers/LowLevelERC20.sol";

contract ERC20TransferManager is LowLevelERC20 {
    address public immutable aggregator;

    error InvalidCaller();

    /**
     * @param _aggregator LooksRareAggregator's address
     */
    constructor(address _aggregator) {
        aggregator = _aggregator;
    }

    /**
     * @notice Pull ERC-20 tokens from the buyer.
     * @param tokenTransfers An array of ERC-20 tokens to pull
     * @param source The address to pull ERC-20 tokens from
     */
    function pullERC20Tokens(TokenTransfer[] calldata tokenTransfers, address source) external {
        if (msg.sender != aggregator) revert InvalidCaller();

        uint256 tokenTransfersLength = tokenTransfers.length;
        for (uint256 i; i < tokenTransfersLength; ) {
            _executeERC20TransferFrom(tokenTransfers[i].currency, source, aggregator, tokenTransfers[i].amount);
            unchecked {
                ++i;
            }
        }
    }
}
