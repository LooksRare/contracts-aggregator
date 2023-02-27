// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @title ITransferManager
 * @author LooksRare protocol team (👀,💎)
 */
interface ITransferManager {
    function grantApprovals(address[] calldata operators) external;
}
