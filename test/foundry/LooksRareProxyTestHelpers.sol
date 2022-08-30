// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import {BasicOrder} from "../../contracts/libraries/OrderStructs.sol";
import {CollectionType} from "../../contracts/libraries/OrderEnums.sol";

abstract contract LooksRareProxyTestHelpers {
    address internal constant BAYC = 0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D;
    address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    function validBAYCOrders() internal pure returns (BasicOrder[] memory orders) {
        orders = new BasicOrder[](2);

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1;

        orders[0].signer = 0x2137213d50207Edfd92bCf4CF7eF9E491A155357;
        orders[0].collection = BAYC;
        orders[0].collectionType = CollectionType.ERC721;
        uint256[] memory orderOneTokenIds = new uint256[](1);
        orderOneTokenIds[0] = 7139;
        orders[0].tokenIds = orderOneTokenIds;
        orders[0].amounts = amounts;
        orders[0].price = 81.8 ether;
        orders[0].currency = WETH;
        orders[0].startTime = 1659632508;
        orders[0].endTime = 1662186976;
        orders[0]
            .signature = hex"e669f75ee8768c3dc4a7ac11f2d301f9dbfced5c1f3c13c7f445ad84d326db4b0f2da0827bac814c4ed782b661ef40dcb2fa71141ef8239a5e5f1038e117549c1c";

        orders[1].signer = 0xaf0f4479aF9Df756b9b2c69B463214B9a3346443;
        orders[1].collection = BAYC;
        orders[1].collectionType = CollectionType.ERC721;
        uint256[] memory orderTwoTokenIds = new uint256[](1);
        orderTwoTokenIds[0] = 3939;
        orders[1].tokenIds = orderTwoTokenIds;
        orders[1].amounts = amounts;
        orders[1].price = 83.391 ether;
        orders[1].currency = WETH;
        orders[1].startTime = 1659484473;
        orders[1].endTime = 1660089268;
        orders[1]
            .signature = hex"146a8f500fea9cde68c339da9abe8654ffb60c5a80506532e3500d1edba687640519093ff36ab3a728c961fc763d6e6a107ed823cfa5bd45182cab8029dab5d21b";
    }
}
