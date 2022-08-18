// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import {ISudoswapRouter} from "../interfaces/ISudoswapRouter.sol";
import {BasicOrder} from "../libraries/OrderStructs.sol";
import {IProxy} from "./IProxy.sol";

/**
 * @title SudoswapProxy
 * @notice This contract allows NFT sweepers to batch buy NFTs from SudoswapProxy
 *         by passing high-level structs + low-level bytes as calldata.
 * @author LooksRare protocol team (👀,💎)
 */
contract SudoswapProxy is IProxy {
    ISudoswapRouter constant ROUTER = ISudoswapRouter(0x2B2e8cDA09bBA9660dCA5cB6233787738Ad68329);

    /// @notice Execute Sudoswap NFT sweeps in a single transaction
    /// @dev Only the 1st argument orders is used
    /// @param orders Orders to be executed by Seaport
    /// @return Whether at least 1 out of N trades succeeded
    function buyWithETH(
        BasicOrder[] calldata orders,
        bytes[] calldata,
        bytes memory,
        bool
    ) external payable override returns (bool) {
        uint256 ordersLength = orders.length;
        if (ordersLength == 0) revert InvalidOrderLength();

        ISudoswapRouter.RobustPairSwapSpecific[] memory swapList = new ISudoswapRouter.RobustPairSwapSpecific[](
            orders.length
        );

        address recipient = orders[0].recipient;
        if (recipient == address(0)) revert ZeroAddress();

        for (uint256 i; i < ordersLength; ) {
            ISudoswapRouter.RobustPairSwapSpecific memory robustPairSwapSpecific;
            ISudoswapRouter.PairSwapSpecific memory pairSwapSpecific;
            robustPairSwapSpecific.maxCost = orders[i].price;
            // here the collection is the AMM pool address
            pairSwapSpecific.pair = orders[i].collection;
            pairSwapSpecific.nftIds = orders[i].tokenIds;
            robustPairSwapSpecific.swapInfo = pairSwapSpecific;

            swapList[i] = robustPairSwapSpecific;

            unchecked {
                ++i;
            }
        }
        // There is no need to do a try/catch here as there is only 1 external call
        // and if it fails the aggregator will catch it and decide whether to revert.
        ROUTER.robustSwapETHForSpecificNFTs{value: msg.value}(swapList, payable(recipient), recipient, block.timestamp);

        return true;
    }
}
