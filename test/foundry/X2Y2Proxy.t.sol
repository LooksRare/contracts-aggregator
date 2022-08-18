// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import {OwnableTwoSteps} from "@looksrare/contracts-libs/contracts/OwnableTwoSteps.sol";
import {X2Y2Proxy} from "../../contracts/proxies/X2Y2Proxy.sol";
import {IProxy} from "../../contracts/proxies/IProxy.sol";
import {BasicOrder} from "../../contracts/libraries/OrderStructs.sol";
import {CollectionType} from "../../contracts/libraries/OrderEnums.sol";
import {Market} from "../../contracts/libraries/x2y2/MarketConsts.sol";
import {TestHelpers} from "./TestHelpers.sol";

abstract contract TestParameters {
    address internal constant X2Y2 = 0x74312363e45DCaBA76c59ec49a7Aa8A65a67EeD3;
    address internal constant BAYC = 0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D;
    address internal _buyer = address(1);
}

contract X2Y2ProxyTest is TestParameters, TestHelpers {
    X2Y2Proxy x2y2Proxy;

    function setUp() public {
        x2y2Proxy = new X2Y2Proxy(X2Y2);
        vm.deal(_buyer, 100 ether);
    }

    function testBuyWithETHZeroOrders() public asPrankedUser(_buyer) {
        BasicOrder[] memory orders = new BasicOrder[](0);
        bytes[] memory ordersExtraData = new bytes[](0);

        vm.expectRevert(IProxy.InvalidOrderLength.selector);
        x2y2Proxy.buyWithETH(orders, ordersExtraData, "", false);
    }

    function testBuyWithETHOrdersLengthMismatch() public asPrankedUser(_buyer) {
        BasicOrder[] memory orders = validBAYCOrder();

        bytes[] memory ordersExtraData = new bytes[](2);
        ordersExtraData[0] = validBAYCOrderExtraData();
        ordersExtraData[1] = validBAYCOrderExtraData();

        vm.expectRevert(IProxy.InvalidOrderLength.selector);
        x2y2Proxy.buyWithETH{value: orders[0].price}(orders, ordersExtraData, "", false);
    }

    function testBuyWithETHOrdersRecipientZeroAddress() public {
        BasicOrder[] memory orders = validBAYCOrder();
        orders[0].recipient = address(0);

        bytes[] memory ordersExtraData = new bytes[](1);
        ordersExtraData[0] = validBAYCOrderExtraData();

        vm.expectRevert(IProxy.ZeroAddress.selector);
        x2y2Proxy.buyWithETH{value: orders[0].price}(orders, ordersExtraData, "", false);
    }

    function validBAYCOrder() private view returns (BasicOrder[] memory orders) {
        orders = new BasicOrder[](1);
        orders[0].signer = 0xCeE749F1CFc66cd3FB57CEfDe8A9c5999FbE7b8F;
        orders[0].recipient = payable(_buyer);
        orders[0].collection = BAYC;
        orders[0].collectionType = CollectionType.ERC721;

        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 2674;
        orders[0].tokenIds = tokenIds;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1;
        orders[0].amounts = amounts;

        orders[0].price = 75.98 ether;
        orders[0].currency = address(0);
        orders[0].startTime = 0;
        orders[0].endTime = 1660785244;
        orders[0]
            .signature = "0x6b9bc049c00da1de15ad5001025976b5aa3537aad2da1af73bd6cba3c06663236167dcd1ab4af8b6be30ac62420edfe67fa9ce50fc721312c3de87804e5c46e21b";
    }

    function validBAYCOrderExtraData() private pure returns (bytes memory orderExtraData) {
        Market.Fee[] memory fees = new Market.Fee[](2);
        fees[0].percentage = 5000;
        fees[0].to = 0xD823C605807cC5E6Bd6fC0d7e4eEa50d3e2d66cd;
        fees[1].percentage = 25000;
        fees[1].to = 0xA858DDc0445d8131daC4d1DE01f834ffcbA52Ef1;

        orderExtraData = abi.encode(
            125818842001394154037499544483314829739,
            "0x00000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000001000000000000000000000000bc4ca0eda7647a8ab7c2061c2e118a18a936f13d0000000000000000000000000000000000000000000000000000000000000a72",
            982243216670505,
            1660595707,
            0xF849de01B080aDC3A814FaBE1E2087475cF2E354,
            27,
            0xe8f82fb4e1e674d1388d7df80b97414c0e7d34e38b2b73ba343929f7fa14bdd7,
            0x19005bc11b6779ae163798357f0bc201157cef4c3d1cee65594ce4e36b23d041,
            fees
        );
    }
}
