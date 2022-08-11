// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import {ISudoswapRouter} from "../interfaces/ISudoswapRouter.sol";
import {BasicOrder} from "../libraries/OrderStructs.sol";

contract SudoswapProxy {
    ISudoswapRouter constant ROUTER = ISudoswapRouter(0x2B2e8cDA09bBA9660dCA5cB6233787738Ad68329);

    function buyWithETH(
        BasicOrder[] calldata orders,
        bytes[] calldata,
        bytes memory
    ) external payable {
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
        ROUTER.robustSwapETHForSpecificNFTs{value: msg.value}(swapList, payable(recipient), recipient, block.timestamp);
    }
}
