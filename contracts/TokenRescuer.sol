// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {OwnableTwoSteps} from "@looksrare/contracts-libs/contracts/OwnableTwoSteps.sol";
import {LowLevelETH} from "./lowLevelCallers/LowLevelETH.sol";
import {LowLevelERC20} from "./lowLevelCallers/LowLevelERC20.sol";

/**
 * @title TokenRescuer
 * @notice This contract allows contract owners to rescue trapped tokens
 * @author LooksRare protocol team (👀,💎)
 */
contract TokenRescuer is OwnableTwoSteps, LowLevelETH, LowLevelERC20 {
    error InsufficientAmount();

    /**
     * @notice Rescue the contract's trapped ETH
     * @dev Must be called by the current owner
     * @param to Send the contract's ETH balance to this address
     */
    function rescueETH(address to) external onlyOwner {
        uint256 withdrawAmount = address(this).balance - 1;
        if (withdrawAmount == 0) revert InsufficientAmount();
        _transferETH(to, withdrawAmount);
    }

    /**
     * @notice Rescue any of the contract's trapped ERC-20 tokens
     * @dev Must be called by the current owner
     * @param currency The address of the ERC-20 token to rescue from the contract
     * @param to Send the contract's specified ERC-20 token balance to this address
     */
    function rescueERC20(address currency, address to) external onlyOwner {
        uint256 withdrawAmount = IERC20(currency).balanceOf(address(this)) - 1;
        if (withdrawAmount == 0) revert InsufficientAmount();
        _executeERC20DirectTransfer(currency, to, withdrawAmount);
    }
}
