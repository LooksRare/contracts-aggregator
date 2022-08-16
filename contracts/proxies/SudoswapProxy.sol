// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import {ISudoswapRouter} from "../interfaces/ISudoswapRouter.sol";
import {BasicOrder} from "../libraries/OrderStructs.sol";
import {IProxy} from "./IProxy.sol";

contract SudoswapProxy is IProxy {
    ISudoswapRouter constant ROUTER = ISudoswapRouter(0x2B2e8cDA09bBA9660dCA5cB6233787738Ad68329);

    function buyWithETH(
        BasicOrder[] calldata orders,
        bytes[] calldata,
        bytes memory,
        bool
    ) external payable override returns (bool) {
        ISudoswapRouter.RobustPairSwapSpecific[] memory swapList = new ISudoswapRouter.RobustPairSwapSpecific[](
            orders.length
        );

        address recipient = orders[0].recipient;

        for (uint256 i; i < orders.length; ) {
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
