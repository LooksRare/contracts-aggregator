// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import {CryptoPunksProxy} from "../../contracts/proxies/CryptoPunksProxy.sol";
import {IProxy} from "../../contracts/proxies/IProxy.sol";
import {BasicOrder} from "../../contracts/libraries/OrderStructs.sol";
import {CollectionType} from "../../contracts/libraries/OrderEnums.sol";
import {TestHelpers} from "./TestHelpers.sol";

abstract contract TestParameters {
    address internal constant CRYPTOPUNKS = 0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB;
    address internal _buyer = address(1);
}

contract CryptoPunksProxyTest is TestParameters, TestHelpers {
    CryptoPunksProxy cryptoPunksProxy;

    function setUp() public {
        cryptoPunksProxy = new CryptoPunksProxy(CRYPTOPUNKS);
        vm.deal(_buyer, 100 ether);
    }

    function testBuyWithETHZeroOrders() public asPrankedUser(_buyer) {
        BasicOrder[] memory orders = new BasicOrder[](0);
        bytes[] memory ordersExtraData = new bytes[](0);

        vm.expectRevert(IProxy.InvalidOrderLength.selector);
        cryptoPunksProxy.buyWithETH(orders, ordersExtraData, "", false);
    }

    function testBuyWithETHOrdersRecipientZeroAddress() public {
        BasicOrder[] memory orders = validCryptoPunksOrder();
        orders[0].recipient = address(0);
        bytes[] memory ordersExtraData = new bytes[](0);

        vm.expectRevert(IProxy.ZeroAddress.selector);
        cryptoPunksProxy.buyWithETH{value: orders[0].price}(orders, ordersExtraData, "", false);
    }

    function validCryptoPunksOrder() private view returns (BasicOrder[] memory orders) {
        orders = new BasicOrder[](1);
        orders[0].signer = address(0);
        orders[0].recipient = payable(_buyer);
        orders[0].collection = CRYPTOPUNKS;
        orders[0].collectionType = CollectionType.ERC721;

        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 3149;
        orders[0].tokenIds = tokenIds;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1;
        orders[0].amounts = amounts;

        orders[0].price = 68.5 ether;
        orders[0].currency = address(0);
        orders[0].startTime = 0;
        orders[0].endTime = 0;
        orders[0].signature = "";
    }
}
