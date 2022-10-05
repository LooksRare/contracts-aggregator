// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {LooksRareAggregator} from "../../contracts/LooksRareAggregator.sol";
import {LooksRareProxy} from "../../contracts/proxies/LooksRareProxy.sol";
import {ILooksRareAggregator} from "../../contracts/interfaces/ILooksRareAggregator.sol";
import {BasicOrder, TokenTransfer} from "../../contracts/libraries/OrderStructs.sol";
import {MockERC20} from "./utils/MockERC20.sol";
import {TestHelpers} from "./TestHelpers.sol";
import {LooksRareProxyTestHelpers} from "./LooksRareProxyTestHelpers.sol";

abstract contract TestParameters {
    address internal constant LOOKSRARE_V1 = 0x59728544B08AB483533076417FbBB2fD0B17CE3a;
    address internal constant LOOKSRARE_STRATEGY_FIXED_PRICE = 0x56244Bb70CbD3EA9Dc8007399F61dFC065190031;
    address internal constant _buyer = address(2);
}

contract LooksRareAggregatorTradesTest is TestParameters, TestHelpers, ILooksRareAggregator, LooksRareProxyTestHelpers {
    LooksRareAggregator aggregator;
    LooksRareProxy looksRareProxy;

    function execute(
        TokenTransfer[] calldata,
        TradeData[] calldata,
        address,
        address,
        bool
    ) external payable {
        revert("This contract inherits from ILooksRareAggregator so execute has to be defined");
    }

    function setUp() public {
        aggregator = new LooksRareAggregator();
        looksRareProxy = new LooksRareProxy(LOOKSRARE_V1, address(aggregator));
    }

    function testBuyWithETHZeroOriginator() public {
        // Since we are forking mainnet, we have to make sure it has 0 ETH.
        vm.deal(address(looksRareProxy), 0);

        aggregator.addFunction(address(looksRareProxy), LooksRareProxy.execute.selector);

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
            extraData: ""
        });

        vm.deal(_buyer, orders[0].price);
        vm.prank(_buyer);
        vm.expectEmit(true, false, false, false);
        emit Sweep(_buyer);
        aggregator.execute{value: orders[0].price}(tokenTransfers, tradeData, address(0), _buyer, false);

        assertEq(IERC721(BAYC).ownerOf(7139), _buyer);
    }
}
