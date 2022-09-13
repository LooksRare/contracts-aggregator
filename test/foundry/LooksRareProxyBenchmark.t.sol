// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import {ILooksRareExchange} from "@looksrare/contracts-exchange-v1/contracts/interfaces/ILooksRareExchange.sol";
import {OrderTypes} from "@looksrare/contracts-exchange-v1/contracts/libraries/OrderTypes.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {LooksRareProxy} from "../../contracts/proxies/LooksRareProxy.sol";
import {LooksRareAggregator} from "../../contracts/LooksRareAggregator.sol";
import {V0Aggregator} from "../../contracts/V0Aggregator.sol";
import {ILooksRareAggregator} from "../../contracts/interfaces/ILooksRareAggregator.sol";
import {IProxy} from "../../contracts/proxies/IProxy.sol";
import {BasicOrder, TokenTransfer, FeeData} from "../../contracts/libraries/OrderStructs.sol";
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
        aggregator.addFunction(address(looksRareProxy), LooksRareProxy.execute.selector);

        v0Aggregator = new V0Aggregator();
        v0Aggregator.addFunction(address(looksRareProxy), LooksRareProxy.execute.selector);
    }

    function testBuyWithETHDirectlySingleOrder() public asPrankedUser(_buyer) {
        ILooksRareExchange looksRare = ILooksRareExchange(LOOKSRARE_V1);

        OrderTypes.MakerOrder memory makerAsk;
        {
            makerAsk.isOrderAsk = true;
            makerAsk.signer = 0x2137213d50207Edfd92bCf4CF7eF9E491A155357;
            makerAsk.collection = BAYC;
            makerAsk.tokenId = 7139;
            makerAsk.price = 81.8 ether;
            makerAsk.amount = 1;
            makerAsk.strategy = 0x56244Bb70CbD3EA9Dc8007399F61dFC065190031;
            makerAsk.nonce = 0;
            makerAsk.minPercentageToAsk = 9550;
            makerAsk.currency = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
            makerAsk.startTime = 1659632508;
            makerAsk.endTime = 1662186976;

            makerAsk.v = 28;
            makerAsk.r = 0xe669f75ee8768c3dc4a7ac11f2d301f9dbfced5c1f3c13c7f445ad84d326db4b;
            makerAsk.s = 0x0f2da0827bac814c4ed782b661ef40dcb2fa71141ef8239a5e5f1038e117549c;
        }

        OrderTypes.TakerOrder memory takerBid;
        {
            takerBid.isOrderAsk = false;
            takerBid.taker = _buyer;
            takerBid.price = 81.8 ether;
            takerBid.tokenId = 7139;
            takerBid.minPercentageToAsk = 9550;
        }

        uint256 gasRemaining = gasleft();
        looksRare.matchAskWithTakerBidUsingETHAndWETH{value: 81.8 ether}(takerBid, makerAsk);
        uint256 gasConsumed = gasRemaining - gasleft();
        emit log_named_uint("LooksRare single NFT purchase through the proxy consumed: ", gasConsumed);

        assertEq(IERC721(BAYC).ownerOf(7139), _buyer);
    }

    function testBuyWithETHDirectlyFromProxySingleOrder() public {
        FeeData memory feeData;
        BasicOrder[] memory validOrders = validBAYCOrders();
        BasicOrder[] memory orders = new BasicOrder[](1);
        orders[0] = validOrders[0];

        bytes[] memory ordersExtraData = new bytes[](1);
        ordersExtraData[0] = abi.encode(orders[0].price, 9550, 0, LOOKSRARE_STRATEGY_FIXED_PRICE);

        uint256 gasRemaining = gasleft();
        looksRareProxy.execute{value: orders[0].price}(orders, ordersExtraData, "", _buyer, false, feeData);
        uint256 gasConsumed = gasRemaining - gasleft();
        emit log_named_uint("LooksRare single NFT purchase through the proxy consumed: ", gasConsumed);

        assertEq(IERC721(BAYC).ownerOf(7139), _buyer);
    }

    function testBuyWithETHThroughAggregatorSingleOrder() public {
        TokenTransfer[] memory tokenTransfers = new TokenTransfer[](0);
        BasicOrder[] memory validOrders = validBAYCOrders();
        BasicOrder[] memory orders = new BasicOrder[](1);
        orders[0] = validOrders[0];

        bytes[] memory ordersExtraData = new bytes[](1);
        ordersExtraData[0] = abi.encode(orders[0].price, 9550, 0, LOOKSRARE_STRATEGY_FIXED_PRICE);

        ILooksRareAggregator.TradeData[] memory tradeData = new ILooksRareAggregator.TradeData[](1);
        tradeData[0] = ILooksRareAggregator.TradeData({
            proxy: address(looksRareProxy),
            selector: LooksRareProxy.execute.selector,
            value: orders[0].price,
            orders: orders,
            ordersExtraData: ordersExtraData,
            extraData: "",
            tokenTransfers: new TokenTransfer[](0)
        });

        uint256 gasRemaining = gasleft();
        aggregator.execute{value: orders[0].price}(tokenTransfers, tradeData, _buyer, false);
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
            LooksRareProxy.execute.selector,
            orders,
            ordersExtraData,
            "",
            _buyer,
            true
        );

        V0Aggregator.TradeData[] memory tradeData = new V0Aggregator.TradeData[](1);
        tradeData[0] = V0Aggregator.TradeData({proxy: address(looksRareProxy), data: data, value: orders[0].price});

        uint256 gasRemaining = gasleft();
        v0Aggregator.execute{value: orders[0].price}(tradeData);
        uint256 gasConsumed = gasRemaining - gasleft();
        emit log_named_uint("LooksRare single NFT purchase through the V0 aggregator consumed: ", gasConsumed);

        assertEq(IERC721(BAYC).ownerOf(7139), _buyer);
    }

    function testBuyWithETHDirectlyFromProxyTwoOrders() public {
        FeeData memory feeData;
        BasicOrder[] memory orders = validBAYCOrders();

        bytes[] memory ordersExtraData = new bytes[](2);
        ordersExtraData[0] = abi.encode(orders[0].price, 9550, 0, LOOKSRARE_STRATEGY_FIXED_PRICE);
        ordersExtraData[1] = abi.encode(orders[1].price, 8500, 50, LOOKSRARE_STRATEGY_FIXED_PRICE);

        uint256 gasRemaining = gasleft();
        looksRareProxy.execute{value: orders[0].price + orders[1].price}(
            orders,
            ordersExtraData,
            "",
            _buyer,
            false,
            feeData
        );
        uint256 gasConsumed = gasRemaining - gasleft();
        emit log_named_uint("LooksRare multiple NFT purchase through the proxy consumed: ", gasConsumed);

        assertEq(IERC721(BAYC).ownerOf(7139), _buyer);
        assertEq(IERC721(BAYC).ownerOf(3939), _buyer);
    }

    function testBuyWithETHThroughAggregatorTwoOrders() public {
        TokenTransfer[] memory tokenTransfers = new TokenTransfer[](0);
        BasicOrder[] memory orders = validBAYCOrders();

        bytes[] memory ordersExtraData = new bytes[](2);
        ordersExtraData[0] = abi.encode(orders[0].price, 9550, 0, LOOKSRARE_STRATEGY_FIXED_PRICE);
        ordersExtraData[1] = abi.encode(orders[1].price, 8500, 50, LOOKSRARE_STRATEGY_FIXED_PRICE);

        ILooksRareAggregator.TradeData[] memory tradeData = new ILooksRareAggregator.TradeData[](1);
        tradeData[0] = ILooksRareAggregator.TradeData({
            proxy: address(looksRareProxy),
            selector: LooksRareProxy.execute.selector,
            value: orders[0].price + orders[1].price,
            orders: orders,
            ordersExtraData: ordersExtraData,
            extraData: "",
            tokenTransfers: new TokenTransfer[](0)
        });

        uint256 gasRemaining = gasleft();
        aggregator.execute{value: orders[0].price + orders[1].price}(tokenTransfers, tradeData, _buyer, false);
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
            LooksRareProxy.execute.selector,
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
        v0Aggregator.execute{value: totalPrice}(tradeData);
        uint256 gasConsumed = gasRemaining - gasleft();
        emit log_named_uint("LooksRare multiple NFT purchase through the V0 aggregator consumed: ", gasConsumed);

        assertEq(IERC721(BAYC).ownerOf(7139), _buyer);
        assertEq(IERC721(BAYC).ownerOf(3939), _buyer);
    }
}
