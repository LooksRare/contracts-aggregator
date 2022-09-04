// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {SeaportProxy} from "../../contracts/proxies/SeaportProxy.sol";
import {LooksRareAggregator} from "../../contracts/LooksRareAggregator.sol";
import {V0Aggregator} from "../../contracts/V0Aggregator.sol";
import {ILooksRareAggregator} from "../../contracts/interfaces/ILooksRareAggregator.sol";
import {IProxy} from "../../contracts/proxies/IProxy.sol";
import {BasicOrder} from "../../contracts/libraries/OrderStructs.sol";
import {TestHelpers} from "./TestHelpers.sol";
import {SeaportProxyTestHelpers} from "./SeaportProxyTestHelpers.sol";

abstract contract TestParameters {
    address internal constant BAYC = 0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D;
    address internal constant SEAPORT = 0x00000000006c3852cbEf3e08E8dF289169EdE581;
    address internal constant _buyer = address(1);
}

contract SeaportProxyBenchmarkTest is TestParameters, TestHelpers, SeaportProxyTestHelpers {
    V0Aggregator v0Aggregator;
    LooksRareAggregator aggregator;
    SeaportProxy seaportProxy;

    function setUp() public {
        seaportProxy = new SeaportProxy(SEAPORT);
        vm.deal(_buyer, 100 ether);
        // Since we are forking mainnet, we have to make sure it has 0 ETH.
        vm.deal(address(seaportProxy), 0);

        aggregator = new LooksRareAggregator();
        aggregator.addFunction(address(seaportProxy), SeaportProxy.buyWithETH.selector);

        v0Aggregator = new V0Aggregator();
        v0Aggregator.addFunction(address(seaportProxy), SeaportProxy.buyWithETH.selector);
    }

    function testBuyWithETHDirectlyFromProxySingleOrder() public {
        BasicOrder memory order = validBAYCId2518Order();
        BasicOrder[] memory orders = new BasicOrder[](1);
        orders[0] = order;

        bytes memory orderExtraData = validBAYCId2518OrderExtraData();
        bytes[] memory ordersExtraData = new bytes[](1);
        ordersExtraData[0] = orderExtraData;
        bytes memory extraData = validSingleBAYCExtraData();

        uint256 gasRemaining = gasleft();
        seaportProxy.buyWithETH{value: order.price}(orders, ordersExtraData, extraData, _buyer, true);
        uint256 gasConsumed = gasRemaining - gasleft();
        emit log_named_uint("Seaport single NFT purchase through the proxy consumed: ", gasConsumed);

        assertEq(IERC721(BAYC).ownerOf(2518), _buyer);
    }

    function testBuyWithETHThroughAggregatorSingleOrder() public {
        BasicOrder memory order = validBAYCId2518Order();
        BasicOrder[] memory orders = new BasicOrder[](1);
        orders[0] = order;

        bytes memory orderExtraData = validBAYCId2518OrderExtraData();
        bytes[] memory ordersExtraData = new bytes[](1);
        ordersExtraData[0] = orderExtraData;

        bytes memory extraData = validSingleBAYCExtraData();

        ILooksRareAggregator.TradeData[] memory tradeData = new ILooksRareAggregator.TradeData[](1);
        tradeData[0] = ILooksRareAggregator.TradeData({
            proxy: address(seaportProxy),
            selector: SeaportProxy.buyWithETH.selector,
            value: order.price,
            orders: orders,
            ordersExtraData: ordersExtraData,
            extraData: extraData
        });

        uint256 gasRemaining = gasleft();
        aggregator.buyWithETH{value: order.price}(tradeData, _buyer, true);
        uint256 gasConsumed = gasRemaining - gasleft();
        emit log_named_uint("Seaport single NFT purchase through the aggregator consumed: ", gasConsumed);

        assertEq(IERC721(BAYC).ownerOf(2518), _buyer);
    }

    function testBuyWithETHThroughV0AggregatorSingleOrder() public {
        BasicOrder memory order = validBAYCId2518Order();
        BasicOrder[] memory orders = new BasicOrder[](1);
        orders[0] = order;

        bytes memory orderExtraData = validBAYCId2518OrderExtraData();
        bytes[] memory ordersExtraData = new bytes[](1);
        ordersExtraData[0] = orderExtraData;

        bytes memory extraData = validSingleBAYCExtraData();

        bytes memory data = abi.encodeWithSelector(
            SeaportProxy.buyWithETH.selector,
            orders,
            ordersExtraData,
            extraData,
            _buyer,
            true
        );

        V0Aggregator.TradeData[] memory tradeData = new V0Aggregator.TradeData[](1);
        tradeData[0] = V0Aggregator.TradeData({proxy: address(seaportProxy), value: order.price, data: data});

        uint256 gasRemaining = gasleft();
        v0Aggregator.buyWithETH{value: order.price}(tradeData);
        uint256 gasConsumed = gasRemaining - gasleft();
        emit log_named_uint("Seaport single NFT purchase through the V0 aggregator consumed: ", gasConsumed);

        assertEq(IERC721(BAYC).ownerOf(2518), _buyer);
    }

    function testBuyWithETHDirectlyFromProxyTwoOrders() public {
        BasicOrder memory orderOne = validBAYCId2518Order();
        BasicOrder memory orderTwo = validBAYCId8498Order();
        BasicOrder[] memory orders = new BasicOrder[](2);
        orders[0] = orderOne;
        orders[1] = orderTwo;

        bytes memory orderOneExtraData = validBAYCId2518OrderExtraData();
        bytes memory orderTwoExtraData = validBAYCId8498OrderExtraData();
        bytes[] memory ordersExtraData = new bytes[](2);
        ordersExtraData[0] = orderOneExtraData;
        ordersExtraData[1] = orderTwoExtraData;

        bytes memory extraData = validMultipleBAYCExtraData();

        uint256 totalPrice = orders[0].price + orders[1].price;

        uint256 gasRemaining = gasleft();
        seaportProxy.buyWithETH{value: totalPrice}(orders, ordersExtraData, extraData, _buyer, true);
        uint256 gasConsumed = gasRemaining - gasleft();
        emit log_named_uint("Seaport multiple NFT purchase through the proxy consumed: ", gasConsumed);

        assertEq(IERC721(BAYC).ownerOf(2518), _buyer);
        assertEq(IERC721(BAYC).ownerOf(8498), _buyer);
    }

    function testBuyWithETHThroughAggregatorTwoOrders() public {
        BasicOrder memory orderOne = validBAYCId2518Order();
        BasicOrder memory orderTwo = validBAYCId8498Order();
        BasicOrder[] memory orders = new BasicOrder[](2);
        orders[0] = orderOne;
        orders[1] = orderTwo;

        bytes memory orderOneExtraData = validBAYCId2518OrderExtraData();
        bytes memory orderTwoExtraData = validBAYCId8498OrderExtraData();
        bytes[] memory ordersExtraData = new bytes[](2);
        ordersExtraData[0] = orderOneExtraData;
        ordersExtraData[1] = orderTwoExtraData;

        bytes memory extraData = validMultipleBAYCExtraData();

        ILooksRareAggregator.TradeData[] memory tradeData = new ILooksRareAggregator.TradeData[](1);
        uint256 totalPrice = orders[0].price + orders[1].price;
        tradeData[0] = ILooksRareAggregator.TradeData({
            proxy: address(seaportProxy),
            selector: SeaportProxy.buyWithETH.selector,
            value: totalPrice,
            orders: orders,
            ordersExtraData: ordersExtraData,
            extraData: extraData
        });

        uint256 gasRemaining = gasleft();
        seaportProxy.buyWithETH{value: totalPrice}(orders, ordersExtraData, extraData, _buyer, true);
        uint256 gasConsumed = gasRemaining - gasleft();
        emit log_named_uint("Seaport multiple NFT purchase through the aggregator consumed: ", gasConsumed);

        assertEq(IERC721(BAYC).ownerOf(2518), _buyer);
        assertEq(IERC721(BAYC).ownerOf(8498), _buyer);
    }

    function testBuyWithETHThroughV0AggregatorTwoOrders() public {
        BasicOrder memory orderOne = validBAYCId2518Order();
        BasicOrder memory orderTwo = validBAYCId8498Order();
        BasicOrder[] memory orders = new BasicOrder[](2);
        orders[0] = orderOne;
        orders[1] = orderTwo;

        bytes memory orderOneExtraData = validBAYCId2518OrderExtraData();
        bytes memory orderTwoExtraData = validBAYCId8498OrderExtraData();
        bytes[] memory ordersExtraData = new bytes[](2);
        ordersExtraData[0] = orderOneExtraData;
        ordersExtraData[1] = orderTwoExtraData;

        bytes memory extraData = validMultipleBAYCExtraData();

        V0Aggregator.TradeData[] memory tradeData = new V0Aggregator.TradeData[](1);
        uint256 totalPrice = orders[0].price + orders[1].price;
        bytes memory data = abi.encodeWithSelector(
            SeaportProxy.buyWithETH.selector,
            orders,
            ordersExtraData,
            extraData,
            _buyer,
            true
        );
        tradeData[0] = V0Aggregator.TradeData({proxy: address(seaportProxy), value: totalPrice, data: data});

        uint256 gasRemaining = gasleft();
        v0Aggregator.buyWithETH{value: totalPrice}(tradeData);
        uint256 gasConsumed = gasRemaining - gasleft();
        emit log_named_uint("Seaport multiple NFT purchase through the V0 aggregator consumed: ", gasConsumed);

        assertEq(IERC721(BAYC).ownerOf(2518), _buyer);
        assertEq(IERC721(BAYC).ownerOf(8498), _buyer);
    }
}
