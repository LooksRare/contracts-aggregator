// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {LooksRareProxy} from "../../contracts/proxies/LooksRareProxy.sol";
import {LooksRareAggregator} from "../../contracts/LooksRareAggregator.sol";
import {V0Aggregator} from "../../contracts/V0Aggregator.sol";
import {ILooksRareAggregator} from "../../contracts/interfaces/ILooksRareAggregator.sol";
import {IProxy} from "../../contracts/proxies/IProxy.sol";
import {BasicOrder} from "../../contracts/libraries/OrderStructs.sol";
import {TestHelpers} from "./TestHelpers.sol";
import {LooksRareProxyTestHelpers} from "./LooksRareProxyTestHelpers.sol";

abstract contract TestParameters {
    address internal constant LOOKSRARE_V1 = 0x59728544B08AB483533076417FbBB2fD0B17CE3a;
    address internal constant LOOKSRARE_STRATEGY_FIXED_PRICE = 0x56244Bb70CbD3EA9Dc8007399F61dFC065190031;
    address internal constant _buyer = address(1);
}

contract LooksRareProxyBenchmarkTest is TestParameters, TestHelpers, LooksRareProxyTestHelpers {
    V0Aggregator v0Aggregator;
    LooksRareAggregator aggregator;
    LooksRareProxy looksRareProxy;

    function setUp() public {
        looksRareProxy = new LooksRareProxy(LOOKSRARE_V1);
        vm.deal(_buyer, 100 ether);
        // Since we are forking mainnet, we have to make sure it has 0 ETH.
        vm.deal(address(looksRareProxy), 0);

        aggregator = new LooksRareAggregator();
        aggregator.addFunction(address(looksRareProxy), LooksRareProxy.buyWithETH.selector);

        v0Aggregator = new V0Aggregator();
        v0Aggregator.addFunction(address(looksRareProxy), LooksRareProxy.buyWithETH.selector);
    }

    function testBuyWithETHDirectlyFromProxySingleOrder() public {
        BasicOrder[] memory validOrders = validBAYCOrders();
        BasicOrder[] memory orders = new BasicOrder[](1);
        orders[0] = validOrders[0];

        bytes[] memory ordersExtraData = new bytes[](1);
        ordersExtraData[0] = abi.encode(orders[0].price, 9550, 0, LOOKSRARE_STRATEGY_FIXED_PRICE);

        uint256 gasRemaining = gasleft();
        looksRareProxy.buyWithETH{value: orders[0].price}(orders, ordersExtraData, "", _buyer, false);
        uint256 gasConsumed = gasRemaining - gasleft();
        emit log_named_uint("LooksRare single NFT purchase through the proxy consumed: ", gasConsumed);

        assertEq(IERC721(BAYC).ownerOf(7139), _buyer);
    }

    function testBuyWithETHThroughAggregatorSingleOrder() public {
        BasicOrder[] memory validOrders = validBAYCOrders();
        BasicOrder[] memory orders = new BasicOrder[](1);
        orders[0] = validOrders[0];

        bytes[] memory ordersExtraData = new bytes[](1);
        ordersExtraData[0] = abi.encode(orders[0].price, 9550, 0, LOOKSRARE_STRATEGY_FIXED_PRICE);

        ILooksRareAggregator.TradeData[] memory tradeData = new ILooksRareAggregator.TradeData[](1);
        tradeData[0] = ILooksRareAggregator.TradeData({
            proxy: address(looksRareProxy),
            selector: LooksRareProxy.buyWithETH.selector,
            value: orders[0].price,
            orders: orders,
            ordersExtraData: ordersExtraData,
            extraData: ""
        });

        uint256 gasRemaining = gasleft();
        aggregator.buyWithETH{value: orders[0].price}(tradeData, _buyer, false);
        uint256 gasConsumed = gasRemaining - gasleft();
        emit log_named_uint("LooksRare single NFT purchase through the aggregator consumed: ", gasConsumed);

        assertEq(IERC721(BAYC).ownerOf(7139), _buyer);
    }

    function testBuyWithETHThroughV0AggregatorSingleOrder() public {
        BasicOrder[] memory validOrders = validBAYCOrders();
        BasicOrder[] memory orders = new BasicOrder[](1);
        orders[0] = validOrders[0];

        bytes[] memory ordersExtraData = new bytes[](1);
        ordersExtraData[0] = abi.encode(orders[0].price, 9550, 0, LOOKSRARE_STRATEGY_FIXED_PRICE);

        bytes memory data = abi.encodeWithSelector(
            LooksRareProxy.buyWithETH.selector,
            orders,
            ordersExtraData,
            "",
            _buyer,
            true
        );

        V0Aggregator.TradeData[] memory tradeData = new V0Aggregator.TradeData[](1);
        tradeData[0] = V0Aggregator.TradeData({proxy: address(looksRareProxy), data: data, value: orders[0].price});

        uint256 gasRemaining = gasleft();
        v0Aggregator.buyWithETH{value: orders[0].price}(tradeData);
        uint256 gasConsumed = gasRemaining - gasleft();
        emit log_named_uint("LooksRare single NFT purchase through the V0 aggregator consumed: ", gasConsumed);

        assertEq(IERC721(BAYC).ownerOf(7139), _buyer);
    }

    function testBuyWithETHDirectlyFromProxyTwoOrders() public {
        BasicOrder[] memory orders = validBAYCOrders();

        bytes[] memory ordersExtraData = new bytes[](2);
        ordersExtraData[0] = abi.encode(orders[0].price, 9550, 0, LOOKSRARE_STRATEGY_FIXED_PRICE);
        ordersExtraData[1] = abi.encode(orders[1].price, 8500, 50, LOOKSRARE_STRATEGY_FIXED_PRICE);

        uint256 gasRemaining = gasleft();
        looksRareProxy.buyWithETH{value: orders[0].price + orders[1].price}(orders, ordersExtraData, "", _buyer, false);
        uint256 gasConsumed = gasRemaining - gasleft();
        emit log_named_uint("LooksRare multiple NFT purchase through the proxy consumed: ", gasConsumed);

        assertEq(IERC721(BAYC).ownerOf(7139), _buyer);
        assertEq(IERC721(BAYC).ownerOf(3939), _buyer);
    }

    function testBuyWithETHThroughAggregatorTwoOrders() public {
        BasicOrder[] memory orders = validBAYCOrders();

        bytes[] memory ordersExtraData = new bytes[](2);
        ordersExtraData[0] = abi.encode(orders[0].price, 9550, 0, LOOKSRARE_STRATEGY_FIXED_PRICE);
        ordersExtraData[1] = abi.encode(orders[1].price, 8500, 50, LOOKSRARE_STRATEGY_FIXED_PRICE);

        ILooksRareAggregator.TradeData[] memory tradeData = new ILooksRareAggregator.TradeData[](1);
        tradeData[0] = ILooksRareAggregator.TradeData({
            proxy: address(looksRareProxy),
            selector: LooksRareProxy.buyWithETH.selector,
            value: orders[0].price + orders[1].price,
            orders: orders,
            ordersExtraData: ordersExtraData,
            extraData: ""
        });

        uint256 gasRemaining = gasleft();
        aggregator.buyWithETH{value: orders[0].price + orders[1].price}(tradeData, _buyer, false);
        uint256 gasConsumed = gasRemaining - gasleft();
        emit log_named_uint("LooksRare multiple NFT purchase through the aggregator consumed: ", gasConsumed);

        assertEq(IERC721(BAYC).ownerOf(7139), _buyer);
        assertEq(IERC721(BAYC).ownerOf(3939), _buyer);
    }

    function testBuyWithETHThroughV0AggregatorTwoOrders() public {
        BasicOrder[] memory orders = validBAYCOrders();

        bytes[] memory ordersExtraData = new bytes[](2);
        ordersExtraData[0] = abi.encode(orders[0].price, 9550, 0, LOOKSRARE_STRATEGY_FIXED_PRICE);
        ordersExtraData[1] = abi.encode(orders[1].price, 8500, 50, LOOKSRARE_STRATEGY_FIXED_PRICE);

        bytes memory data = abi.encodeWithSelector(
            LooksRareProxy.buyWithETH.selector,
            orders,
            ordersExtraData,
            "",
            _buyer,
            true
        );

        uint256 totalPrice = orders[0].price + orders[1].price;

        V0Aggregator.TradeData[] memory tradeData = new V0Aggregator.TradeData[](1);
        tradeData[0] = V0Aggregator.TradeData({proxy: address(looksRareProxy), data: data, value: totalPrice});

        uint256 gasRemaining = gasleft();
        v0Aggregator.buyWithETH{value: totalPrice}(tradeData);
        uint256 gasConsumed = gasRemaining - gasleft();
        emit log_named_uint("LooksRare multiple NFT purchase through the V0 aggregator consumed: ", gasConsumed);

        assertEq(IERC721(BAYC).ownerOf(7139), _buyer);
        assertEq(IERC721(BAYC).ownerOf(3939), _buyer);
    }
}
