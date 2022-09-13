// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import {BasicOrder} from "../libraries/OrderStructs.sol";

interface IProxy {
    error FeeTooHigh();
    error InvalidOrderLength();
    error UncallableFunction();
    error ZeroAddress();

    /**
     * @dev Emitted when the fee recipient is updated
     * @param feeRecipient The new fee recipient
     */
    event FeeRecipientUpdated(address feeRecipient);

    /**
     * @dev Emitted when the fee basis point is updated
     * @param feeBp The new fee basis point
     */
    event FeeUpdated(uint256 feeBp);

    /**
     * @notice Execute NFT sweeps in a single transaction
     * @param orders Orders to be executed
     * @param ordersExtraData Extra data for each order
     * @param extraData Extra data for the whole transaction
     * @param recipient The address to receive the purchased NFTs
     * @param isAtomic Flag to enable atomic trades (all or nothing) or partial trades
     */
    function execute(
        BasicOrder[] calldata orders,
        bytes[] calldata ordersExtraData,
        bytes calldata extraData,
        address recipient,
        bool isAtomic
    ) external payable returns (bool);

    /**
     * @notice Set fee basis point
     * @param _feeBp The new fee basis point
     */
    function setFeeBp(uint256 _feeBp) external;

    /**
     * @notice Set fee recipient
     * @param _feeRecipient The new fee recipient
     */
    function setFeeRecipient(address _feeRecipient) external;
}
