// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IERC1155} from "@looksrare/contracts-libs/contracts/interfaces/generic/IERC1155.sol";
import {SeaportProxy} from "../../contracts/proxies/SeaportProxy.sol";
import {LooksRareAggregator} from "../../contracts/LooksRareAggregator.sol";
import {ILooksRareAggregator} from "../../contracts/interfaces/ILooksRareAggregator.sol";
import {BasicOrder, TokenTransfer} from "../../contracts/libraries/OrderStructs.sol";
import {TestHelpers} from "./TestHelpers.sol";
import {TestParameters} from "./TestParameters.sol";
import {SeaportProxyTestHelpers} from "./SeaportProxyTestHelpers.sol";

/**
 * @notice SeaportProxy ERC1155 tests (fees, refund, atomic fail/partial success)
 */
contract SeaportProxyERC1155Test is TestParameters, TestHelpers, SeaportProxyTestHelpers {
    LooksRareAggregator private aggregator;
    SeaportProxy private seaportProxy;

    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("mainnet"), 15_320_038);

        aggregator = new LooksRareAggregator();
        seaportProxy = new SeaportProxy(SEAPORT, address(aggregator));
        aggregator.addFunction(address(seaportProxy), SeaportProxy.execute.selector);
        vm.deal(_buyer, INITIAL_ETH_BALANCE);
        // Forking from mainnet and the deployed addresses might have balance
        vm.deal(address(aggregator), 1 wei);
        vm.deal(address(seaportProxy), 0);
    }

    function testExecuteAtomic() public asPrankedUser(_buyer) {
        _testExecute(true);
    }

    function testExecuteNonAtomic() public asPrankedUser(_buyer) {
        _testExecute(false);
    }

    function testExecuteRefundFromLooksRareAggregatorAtomic() public asPrankedUser(_buyer) {
        _testExecuteRefundFromLooksRareAggregator(true);
    }

    function testExecuteRefundFromLooksRareAggregatorNonAtomic() public asPrankedUser(_buyer) {
        _testExecuteRefundFromLooksRareAggregator(false);
    }

    function testExecuteAtomicFail() public asPrankedUser(_buyer) {
        ILooksRareAggregator.TradeData[] memory tradeData = _generateTradeData(true);
        TokenTransfer[] memory tokenTransfers = new TokenTransfer[](0);

        vm.expectRevert(SeaportProxy.TradeExecutionFailed.selector); // InsufficientEtherSupplied
        // Not paying for the second order
        aggregator.execute{value: tradeData[0].orders[0].price}(tokenTransfers, tradeData, _buyer, _buyer, true);
    }

    function testExecutePartialSuccess() public asPrankedUser(_buyer) {
        ILooksRareAggregator.TradeData[] memory tradeData = _generateTradeData(false);
        TokenTransfer[] memory tokenTransfers = new TokenTransfer[](0);

        vm.expectEmit(true, true, false, false);
        emit Sweep(_buyer);

        // Not paying for the second order
        aggregator.execute{value: tradeData[0].orders[0].price}(tokenTransfers, tradeData, _buyer, _buyer, false);
        assertEq(IERC1155(CITY_DAO).balanceOf(_buyer, 42), 1);
        assertEq(_buyer.balance, INITIAL_ETH_BALANCE - tradeData[0].orders[0].price);
    }

    function _testExecute(bool isAtomic) private {
        ILooksRareAggregator.TradeData[] memory tradeData = _generateTradeData(isAtomic);
        TokenTransfer[] memory tokenTransfers = new TokenTransfer[](0);

        vm.expectEmit(true, true, false, false);
        emit Sweep(_buyer);

        uint256 value = tradeData[0].orders[0].price + tradeData[0].orders[1].price;
        aggregator.execute{value: tradeData[0].orders[0].price + tradeData[0].orders[1].price}(
            tokenTransfers,
            tradeData,
            _buyer,
            _buyer,
            isAtomic
        );
        assertEq(IERC1155(CITY_DAO).balanceOf(_buyer, 42), 2);
        assertEq(_buyer.balance, INITIAL_ETH_BALANCE - value);
    }

    function _testExecuteRefundFromLooksRareAggregator(bool isAtomic) private {
        ILooksRareAggregator.TradeData[] memory tradeData = _generateTradeData(isAtomic);
        TokenTransfer[] memory tokenTransfers = new TokenTransfer[](0);

        vm.expectEmit(true, true, false, false);
        emit Sweep(_buyer);

        uint256 value = tradeData[0].orders[0].price + tradeData[0].orders[1].price;
        aggregator.execute{value: value + 0.1 ether}(tokenTransfers, tradeData, _buyer, _buyer, isAtomic);
        assertEq(IERC1155(CITY_DAO).balanceOf(_buyer, 42), 2);
        assertEq(_buyer.balance, INITIAL_ETH_BALANCE - value);
    }

    function _generateTradeData(bool isAtomic)
        private
        view
        returns (ILooksRareAggregator.TradeData[] memory tradeData)
    {
        BasicOrder[] memory orders = validCityDaoOrders();
        bytes[] memory ordersExtraData = validCityDaoOrdersExtraData();
        bytes memory extraData = isAtomic ? validMultipleItemsSameCollectionExtraData() : new bytes(0);

        tradeData = new ILooksRareAggregator.TradeData[](1);
        uint256 totalPrice = orders[0].price + orders[1].price;
        tradeData[0] = ILooksRareAggregator.TradeData({
            proxy: address(seaportProxy),
            selector: SeaportProxy.execute.selector,
            maxFeeBp: 0,
            orders: orders,
            ordersExtraData: ordersExtraData,
            extraData: extraData
        });
    }
}
