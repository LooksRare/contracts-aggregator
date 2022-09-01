// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import {ISudoswapRouter} from "../interfaces/ISudoswapRouter.sol";
import {BasicOrder, TokenTransfer} from "../libraries/OrderStructs.sol";
import {TokenLogic} from "../TokenLogic.sol";
import {IProxy} from "./IProxy.sol";

/**
 * @title SudoswapProxy
 * @notice This contract allows NFT sweepers to batch buy NFTs from SudoswapProxy
 *         by passing high-level structs + low-level bytes as calldata.
 * @author LooksRare protocol team (👀,💎)
 */
contract SudoswapProxy is TokenLogic, IProxy {
    ISudoswapRouter public immutable router;

    constructor(address _router) {
        router = ISudoswapRouter(_router);
    }

    /**
     * @notice Execute Sudoswap NFT sweeps in a single transaction
     * @dev tokenTransfers, ordersExtraData and extraData are not used
     * @param orders Orders to be executed by Seaport
     * @param recipient The address to receive the purchased NFTs
     * @param isAtomic Flag to enable atomic trades (all or nothing) or partial trades
     * @return Whether at least 1 out of N trades succeeded
     */
    function execute(
        TokenTransfer[] calldata,
        BasicOrder[] calldata orders,
        bytes[] calldata,
        bytes memory,
        address,
        address recipient,
        bool isAtomic
    ) external payable override returns (bool) {
        uint256 ordersLength = orders.length;
        if (ordersLength == 0) revert InvalidOrderLength();

        if (recipient == address(0)) revert ZeroAddress();

        if (isAtomic) {
            ISudoswapRouter.PairSwapSpecific[] memory swapList = new ISudoswapRouter.PairSwapSpecific[](orders.length);

            for (uint256 i; i < ordersLength; ) {
                ISudoswapRouter.PairSwapSpecific memory pairSwapSpecific;
                // here the collection is the AMM pool address
                pairSwapSpecific.pair = orders[i].collection;
                pairSwapSpecific.nftIds = orders[i].tokenIds;

                swapList[i] = pairSwapSpecific;

                unchecked {
                    ++i;
                }
            }

            router.swapETHForSpecificNFTs{value: msg.value}(swapList, payable(recipient), recipient, block.timestamp);
        } else {
            ISudoswapRouter.RobustPairSwapSpecific[] memory swapList = new ISudoswapRouter.RobustPairSwapSpecific[](
                orders.length
            );

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

            router.robustSwapETHForSpecificNFTs{value: msg.value}(
                swapList,
                payable(recipient),
                recipient,
                block.timestamp
            );
        }

        return true;
    }
}
