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
    function rescueETH(address to) external onlyOwner {
        _transferETH(to, address(this).balance);
    }

    function rescueERC20(address currency, address to) external onlyOwner {
        uint256 amount = IERC20(currency).balanceOf(address(this));
        _executeERC20DirectTransfer(currency, to, amount);
    }
}
