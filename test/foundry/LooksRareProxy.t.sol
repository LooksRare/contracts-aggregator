// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import {OwnableTwoSteps} from "@looksrare/contracts-libs/contracts/OwnableTwoSteps.sol";
import {LooksRareProxy} from "../../contracts/proxies/LooksRareProxy.sol";
import {IProxy} from "../../contracts/proxies/IProxy.sol";
import {BasicOrder} from "../../contracts/libraries/OrderStructs.sol";
import {CollectionType} from "../../contracts/libraries/OrderEnums.sol";
import {TestHelpers} from "./TestHelpers.sol";

abstract contract TestParameters {
    address internal constant BAYC = 0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D;
    address internal constant LOOKSRARE_V1 = 0x59728544B08AB483533076417FbBB2fD0B17CE3a;
    address internal constant LOOKSRARE_STRATEGY_FIXED_PRICE = 0x56244Bb70CbD3EA9Dc8007399F61dFC065190031;
    address internal constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address internal constant _buyer = address(1);
}

contract LooksRareProxyTest is TestParameters, TestHelpers {
    LooksRareProxy looksRareProxy;

    function setUp() public {
        looksRareProxy = new LooksRareProxy(LOOKSRARE_V1);
        vm.deal(_buyer, 100 ether);
    }

    function testBuyWithETHZeroOrders() public asPrankedUser(_buyer) {
        BasicOrder[] memory orders = new BasicOrder[](0);
        bytes[] memory ordersExtraData = new bytes[](0);

        vm.expectRevert(IProxy.InvalidOrderLength.selector);
        looksRareProxy.buyWithETH(orders, ordersExtraData, "", false);
    }

    function testBuyWithETHOrdersLengthMismatch() public asPrankedUser(_buyer) {
        BasicOrder[] memory orders = validBAYCOrder();

        bytes[] memory ordersExtraData = new bytes[](2);
        ordersExtraData[0] = abi.encode(LOOKSRARE_STRATEGY_FIXED_PRICE, 0, 9550);
        ordersExtraData[1] = abi.encode(LOOKSRARE_STRATEGY_FIXED_PRICE, 50, 8500);

        vm.expectRevert(IProxy.InvalidOrderLength.selector);
        looksRareProxy.buyWithETH{value: orders[0].price}(orders, ordersExtraData, "", false);
    }

    function testBuyWithETHOrdersRecipientZeroAddress() public {
        BasicOrder[] memory orders = validBAYCOrder();
        orders[0].recipient = address(0);

        bytes[] memory ordersExtraData = new bytes[](1);
        ordersExtraData[0] = abi.encode(LOOKSRARE_STRATEGY_FIXED_PRICE, 0, 9550);

        vm.expectRevert(IProxy.ZeroAddress.selector);
        looksRareProxy.buyWithETH{value: orders[0].price}(orders, ordersExtraData, "", false);
    }

    function validBAYCOrder() private returns (BasicOrder[] memory orders) {
        orders = new BasicOrder[](1);
        orders[0].signer = 0x2137213d50207Edfd92bCf4CF7eF9E491A155357;
        orders[0].recipient = _buyer;
        orders[0].collection = BAYC;
        orders[0].collectionType = CollectionType.ERC721;
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 7139;
        orders[0].tokenIds = tokenIds;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1;
        orders[0].amounts = amounts;
        orders[0].price = 81.8 ether;
        orders[0].currency = WETH;
        orders[0].startTime = 1659632508;
        orders[0].endTime = 1662186976;
        orders[0]
            .signature = "0xe669f75ee8768c3dc4a7ac11f2d301f9dbfced5c1f3c13c7f445ad84d326db4b0f2da0827bac814c4ed782b661ef40dcb2fa71141ef8239a5e5f1038e117549c1c";
    }
}
