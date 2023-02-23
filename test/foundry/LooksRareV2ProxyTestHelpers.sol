// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {BasicOrder} from "../../contracts/libraries/OrderStructs.sol";
import {CollectionType} from "../../contracts/libraries/OrderEnums.sol";

/**
 * @notice LooksRare V2 orders helper contract
 */
abstract contract LooksRareV2ProxyTestHelpers {
    address internal constant MULTIFACET_NFT_OWNER = 0x7c741AD1dd7Ce77E88e7717De1cC20e3314b4F38;
    address internal constant MULTIFACET_NFT = 0xf5de760f2e916647fd766B4AD9E85ff943cE3A2b;

    function validGoerliTestERC721Orders() internal pure returns (BasicOrder[] memory orders) {
        orders = new BasicOrder[](2);

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1;

        orders[0].signer = MULTIFACET_NFT_OWNER;
        orders[0].collection = MULTIFACET_NFT;
        orders[0].collectionType = CollectionType.ERC721;
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 2828266;
        orders[0].tokenIds = tokenIds;
        orders[0].amounts = amounts;
        orders[0].price = 1 ether;
        orders[0].currency = address(0);
        orders[0].startTime = 1677166047;
        orders[0].endTime = 1679796047;
        orders[0]
            .signature = hex"23d3fc4ef6d68c7b686db297cef3e56c1b78970af6b02e659120a4c8bee0fea70acd6ea0107b5084e15bf79d042348a0099167b7cb7c52af0fbe11fe962344621c";

        amounts = new uint256[](2);
        amounts[0] = 1;
        amounts[1] = 1;

        orders[1].signer = MULTIFACET_NFT_OWNER;
        orders[1].collection = MULTIFACET_NFT;
        orders[1].collectionType = CollectionType.ERC721;
        tokenIds = new uint256[](2);
        tokenIds[0] = 2828267;
        tokenIds[1] = 2828268;
        orders[1].tokenIds = tokenIds;
        orders[1].amounts = amounts;
        orders[1].price = 2 ether;
        orders[1].currency = address(0);
        orders[1].startTime = 1677166047;
        orders[1].endTime = 1679796047;
        orders[1]
            .signature = hex"412973e459a5816a99c0c91407cfc2ca901992a83f6ab477a468c47a90b742e632a01b11949e3d0076fc5481b604f8e1fa0e5e4c969f0ff781ac5afe0ebf41e41c";
    }
}
