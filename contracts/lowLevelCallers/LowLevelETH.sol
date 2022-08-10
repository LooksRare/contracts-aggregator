// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

/**
 * @title LowLevelETH
 * @notice This contract contains low-level calls to transfer ETH.
 * @author LooksRare protocol team (👀,💎)
 */
contract LowLevelETH {
    error TransferFail();

    /**
     * @notice Transfer ETH to address
     * @param _to recipient address
     * @param _amount amount to transfer
     */
    function _transferETH(address _to, uint256 _amount) internal {
        bool status;

        assembly {
            status := call(gas(), _to, _amount, 0, 0, 0, 0)
        }

        if (!status) {
            revert TransferFail();
        }
    }

    /**
     * @notice Return ETH to sender if any is left in the payable call
     */
    function _returnETHIfAny(address _to) internal {
        assembly {
            if gt(selfbalance(), 0) {
                let status := call(gas(), _to, selfbalance(), 0, 0, 0, 0)
            }
        }
    }
}