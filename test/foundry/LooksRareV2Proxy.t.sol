// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IERC721} from "@looksrare/contracts-libs/contracts/interfaces/generic/IERC721.sol";
import {LooksRareV2Proxy} from "../../contracts/proxies/LooksRareV2Proxy.sol";
import {LooksRareAggregator} from "../../contracts/LooksRareAggregator.sol";
import {ILooksRareAggregator} from "../../contracts/interfaces/ILooksRareAggregator.sol";
import {IProxy} from "../../contracts/interfaces/IProxy.sol";
import {ITransferManager} from "../../contracts/interfaces/ITransferManager.sol";
import {BasicOrder, TokenTransfer} from "../../contracts/libraries/OrderStructs.sol";
import {MerkleTree} from "../../contracts/libraries/looksrare-v2/OrderStructs.sol";
import {CollectionType} from "../../contracts/libraries/OrderEnums.sol";
import {InvalidOrderLength} from "../../contracts/libraries/SharedErrors.sol";
import {TestHelpers} from "./TestHelpers.sol";
import {TestParameters} from "./TestParameters.sol";
import {LooksRareV2ProxyTestHelpers} from "./LooksRareV2ProxyTestHelpers.sol";

contract LooksRareV2ProxyTest is TestParameters, TestHelpers, LooksRareV2ProxyTestHelpers {
    LooksRareAggregator private aggregator;
    LooksRareV2Proxy private looksRareV2Proxy;

    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("goerli"), 8_542_878);

        aggregator = new LooksRareAggregator(address(this));
        looksRareV2Proxy = new LooksRareV2Proxy(LOOKSRARE_V2_GOERLI, address(aggregator));
        aggregator.addFunction(address(looksRareV2Proxy), LooksRareV2Proxy.execute.selector);

        vm.deal(_buyer, 200 ether);
        vm.deal(address(aggregator), 1 wei);

        vm.startPrank(0x7c741AD1dd7Ce77E88e7717De1cC20e3314b4F38);
        IERC721(MULTIFACET_NFT).setApprovalForAll(LOOKSRARE_V2_TRANSFER_MANAGER_GOERLI, true);
        address[] memory operators = new address[](1);
        operators[0] = LOOKSRARE_V2_GOERLI;
        ITransferManager(LOOKSRARE_V2_TRANSFER_MANAGER_GOERLI).grantApprovals(operators);
        vm.stopPrank();
    }

    function testExecute() public asPrankedUser(_buyer) {
        ILooksRareAggregator.TradeData[] memory tradeData = _generateTradeData();
        TokenTransfer[] memory tokenTransfers = new TokenTransfer[](0);

        uint256 value = tradeData[0].orders[0].price;

        vm.expectEmit(false, false, false, true);
        emit Sweep(_buyer);
        aggregator.execute{value: value}(tokenTransfers, tradeData, _buyer, _buyer, false);

        assertEq(IERC721(MULTIFACET_NFT).balanceOf(_buyer), 1);
        assertEq(IERC721(MULTIFACET_NFT).ownerOf(2828266), _buyer);
        assertEq(_buyer.balance, 200 ether - value);
    }

    // function testExecuteCallerNotAggregator() public {
    //     looksRareV2Proxy = new looksRareV2Proxy(LOOKSRARE_V1, address(1));
    //     aggregator.addFunction(address(looksRareV2Proxy), looksRareV2Proxy.execute.selector);

    //     ILooksRareAggregator.TradeData[] memory tradeData = _generateTradeData();
    //     TokenTransfer[] memory tokenTransfers = new TokenTransfer[](0);

    //     uint256 value = tradeData[0].orders[0].price + tradeData[0].orders[1].price;

    //     vm.expectRevert(IProxy.InvalidCaller.selector);
    //     aggregator.execute{value: value}(tokenTransfers, tradeData, _buyer, _buyer, true);
    // }

    // function testExecuteAtomicFail() public asPrankedUser(_buyer) {
    //     ILooksRareAggregator.TradeData[] memory tradeData = _generateTradeData();
    //     TokenTransfer[] memory tokenTransfers = new TokenTransfer[](0);

    //     // Pay less for order 0
    //     tradeData[0].orders[0].price -= 0.1 ether;
    //     uint256 value = tradeData[0].orders[0].price + tradeData[0].orders[1].price;

    //     vm.expectRevert("Strategy: Execution invalid");
    //     aggregator.execute{value: value}(tokenTransfers, tradeData, _buyer, _buyer, true);
    // }

    // function testExecutePartialSuccess() public asPrankedUser(_buyer) {
    //     ILooksRareAggregator.TradeData[] memory tradeData = _generateTradeData();
    //     TokenTransfer[] memory tokenTransfers = new TokenTransfer[](0);

    //     // Pay less for order 0
    //     tradeData[0].orders[0].price -= 0.1 ether;
    //     uint256 value = tradeData[0].orders[0].price + tradeData[0].orders[1].price;

    //     vm.expectEmit(false, false, false, true);
    //     emit Sweep(_buyer);
    //     aggregator.execute{value: value}(tokenTransfers, tradeData, _buyer, _buyer, false);

    //     assertEq(IERC721(BAYC).balanceOf(_buyer), 1);
    //     assertEq(IERC721(BAYC).ownerOf(3939), _buyer);
    //     assertEq(_buyer.balance, 200 ether - tradeData[0].orders[1].price);
    // }

    // function testExecuteRefundExtraPaid() public asPrankedUser(_buyer) {
    //     ILooksRareAggregator.TradeData[] memory tradeData = _generateTradeData();
    //     TokenTransfer[] memory tokenTransfers = new TokenTransfer[](0);

    //     uint256 value = tradeData[0].orders[0].price + tradeData[0].orders[1].price + 0.1 ether;

    //     vm.expectEmit(false, false, false, true);
    //     emit Sweep(_buyer);
    //     aggregator.execute{value: value}(tokenTransfers, tradeData, _buyer, _buyer, false);

    //     assertEq(IERC721(BAYC).balanceOf(_buyer), 2);
    //     assertEq(IERC721(BAYC).ownerOf(7139), _buyer);
    //     assertEq(IERC721(BAYC).ownerOf(3939), _buyer);
    //     assertEq(_buyer.balance, 200 ether - value + 0.1 ether);
    // }

    // function testExecuteZeroOrders() public asPrankedUser(_buyer) {
    //     BasicOrder[] memory orders = new BasicOrder[](0);
    //     bytes[] memory ordersExtraData = new bytes[](0);

    //     TokenTransfer[] memory tokenTransfers = new TokenTransfer[](0);

    //     ILooksRareAggregator.TradeData[] memory tradeData = new ILooksRareAggregator.TradeData[](1);
    //     tradeData[0] = ILooksRareAggregator.TradeData({
    //         proxy: address(looksRareV2Proxy),
    //         selector: LooksRareProxy.execute.selector,
    //         orders: orders,
    //         ordersExtraData: ordersExtraData,
    //         extraData: ""
    //     });

    //     vm.expectRevert(InvalidOrderLength.selector);
    //     aggregator.execute{value: 0}(tokenTransfers, tradeData, _buyer, _buyer, true);
    // }

    // function testExecuteOrdersLengthMismatch() public asPrankedUser(_buyer) {
    //     BasicOrder[] memory orders = validBAYCOrders();

    //     bytes[] memory ordersExtraData = new bytes[](1);
    //     ordersExtraData[0] = abi.encode(orders[0].price, 9_550, 0, LOOKSRARE_STRATEGY_FIXED_PRICE);

    //     TokenTransfer[] memory tokenTransfers = new TokenTransfer[](0);

    //     uint256 value = orders[0].price + orders[1].price;

    //     ILooksRareAggregator.TradeData[] memory tradeData = new ILooksRareAggregator.TradeData[](1);
    //     tradeData[0] = ILooksRareAggregator.TradeData({
    //         proxy: address(looksRareV2Proxy),
    //         selector: LooksRareProxy.execute.selector,
    //         orders: orders,
    //         ordersExtraData: ordersExtraData,
    //         extraData: ""
    //     });

    //     vm.expectRevert(InvalidOrderLength.selector);
    //     aggregator.execute{value: value}(tokenTransfers, tradeData, _buyer, _buyer, true);
    // }

    function _generateTradeData() private view returns (ILooksRareAggregator.TradeData[] memory tradeData) {
        BasicOrder[] memory orders = validGoerliTestERC721Orders();
        MerkleTree memory merkleTree;

        bytes[] memory ordersExtraData = new bytes[](1);
        ordersExtraData[0] = abi.encode(
            LooksRareV2Proxy.OrderExtraData({
                merkleTree: merkleTree,
                globalNonce: 0,
                subsetNonce: 0,
                orderNonce: 0,
                strategyId: 0,
                price: orders[0].price,
                takerBidAdditionalParameters: new bytes(0),
                makerAskAdditionalParameters: new bytes(0)
            })
        );

        tradeData = new ILooksRareAggregator.TradeData[](1);
        tradeData[0] = ILooksRareAggregator.TradeData({
            proxy: address(looksRareV2Proxy),
            selector: LooksRareV2Proxy.execute.selector,
            orders: orders,
            ordersExtraData: ordersExtraData,
            extraData: abi.encode(address(0)) // affiliate
        });
    }
}
