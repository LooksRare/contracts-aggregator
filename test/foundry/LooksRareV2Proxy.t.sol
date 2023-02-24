// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IERC721} from "@looksrare/contracts-libs/contracts/interfaces/generic/IERC721.sol";
import {IERC1155} from "@looksrare/contracts-libs/contracts/interfaces/generic/IERC1155.sol";
import {LooksRareV2Proxy} from "../../contracts/proxies/LooksRareV2Proxy.sol";
import {LooksRareAggregator} from "../../contracts/LooksRareAggregator.sol";
import {ILooksRareAggregator} from "../../contracts/interfaces/ILooksRareAggregator.sol";
import {IProxy} from "../../contracts/interfaces/IProxy.sol";
import {ITransferManager} from "../../contracts/interfaces/ITransferManager.sol";
import {BasicOrder, TokenTransfer} from "../../contracts/libraries/OrderStructs.sol";
import {MerkleTree} from "../../contracts/libraries/looksrare-v2/OrderStructs.sol";
import {CollectionType} from "../../contracts/libraries/OrderEnums.sol";
import {InvalidOrderLength, TradeExecutionFailed} from "../../contracts/libraries/SharedErrors.sol";
import {TestHelpers} from "./TestHelpers.sol";
import {TestParameters} from "./TestParameters.sol";
import {LooksRareV2ProxyTestHelpers} from "./LooksRareV2ProxyTestHelpers.sol";

contract LooksRareV2ProxyTest is TestParameters, TestHelpers, LooksRareV2ProxyTestHelpers {
    LooksRareAggregator private aggregator;
    LooksRareV2Proxy private looksRareV2Proxy;

    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("goerli"), 8_543_681);

        vm.deal(LOOKSRARE_V2_GOERLI, 1 wei);

        aggregator = new LooksRareAggregator(address(this));
        looksRareV2Proxy = new LooksRareV2Proxy(LOOKSRARE_V2_GOERLI, address(aggregator));
        aggregator.addFunction(address(looksRareV2Proxy), LooksRareV2Proxy.execute.selector);

        vm.deal(_buyer, 200 ether);
        vm.deal(NFT_OWNER, 200 ether);
        vm.deal(address(aggregator), 1 wei);

        vm.startPrank(NFT_OWNER);
        IERC721(MULTIFACET_NFT).setApprovalForAll(LOOKSRARE_V2_TRANSFER_MANAGER_GOERLI, true);
        IERC1155(TEST_ERC1155).setApprovalForAll(LOOKSRARE_V2_TRANSFER_MANAGER_GOERLI, true);
        address[] memory operators = new address[](1);
        operators[0] = LOOKSRARE_V2_GOERLI;
        ITransferManager(LOOKSRARE_V2_TRANSFER_MANAGER_GOERLI).grantApprovals(operators);
        vm.stopPrank();
    }

    function testExecuteERC721Atomic() public asPrankedUser(_buyer) {
        _testExecuteERC721(true);
    }

    function testExecuteERC721NonAtomic() public asPrankedUser(_buyer) {
        _testExecuteERC721(false);
    }

    function testExecuteERC1155Atomic() public asPrankedUser(_buyer) {
        _testExecuteERC1155(true);
    }

    function testExecuteERC1155NonAtomic() public asPrankedUser(_buyer) {
        _testExecuteERC1155(false);
    }

    function testExecuteCallerNotAggregator() public {
        looksRareV2Proxy = new LooksRareV2Proxy(LOOKSRARE_V2_GOERLI, address(1));
        aggregator.addFunction(address(looksRareV2Proxy), looksRareV2Proxy.execute.selector);

        ILooksRareAggregator.TradeData[] memory tradeData = _generateERC721TradeData();
        TokenTransfer[] memory tokenTransfers = new TokenTransfer[](0);

        uint256 value = tradeData[0].orders[0].price + tradeData[0].orders[1].price;

        vm.expectRevert(IProxy.InvalidCaller.selector);
        vm.prank(_buyer);
        aggregator.execute{value: value}(tokenTransfers, tradeData, _buyer, _buyer, true);
    }

    function testExecuteAtomicFail() public asPrankedUser(_buyer) {
        ILooksRareAggregator.TradeData[] memory tradeData = _generateERC721TradeData();
        TokenTransfer[] memory tokenTransfers = new TokenTransfer[](0);

        uint256 value = tradeData[0].orders[0].price + tradeData[0].orders[1].price - 0.01 ether;

        vm.expectRevert(TradeExecutionFailed.selector);
        aggregator.execute{value: value}(tokenTransfers, tradeData, _buyer, _buyer, true);
    }

    function testExecutePartialSuccess() public {
        ILooksRareAggregator.TradeData[] memory tradeData = _generateERC721TradeData();
        TokenTransfer[] memory tokenTransfers = new TokenTransfer[](0);

        uint256 firstOrderPrice = tradeData[0].orders[0].price;
        uint256 value = firstOrderPrice + tradeData[0].orders[1].price;

        // Seller no longer owns one of the NFTs in the second order
        vm.prank(NFT_OWNER);
        IERC721(MULTIFACET_NFT).transferFrom(NFT_OWNER, address(69), 2828267);

        vm.expectEmit(false, false, false, true);
        emit Sweep(_buyer);
        vm.prank(_buyer);
        aggregator.execute{value: value}(tokenTransfers, tradeData, _buyer, _buyer, false);

        assertEq(IERC721(MULTIFACET_NFT).balanceOf(_buyer), 1);
        assertEq(IERC721(MULTIFACET_NFT).ownerOf(2828266), _buyer);
        assertEq(_buyer.balance, 200 ether - firstOrderPrice);
        assertEq(address(NFT_OWNER).balance, 200 ether + (firstOrderPrice * 9_800) / 10_000);
    }

    function testExecuteRefundExtraPaid() public asPrankedUser(_buyer) {
        ILooksRareAggregator.TradeData[] memory tradeData = _generateERC721TradeData();
        TokenTransfer[] memory tokenTransfers = new TokenTransfer[](0);

        uint256 value = tradeData[0].orders[0].price + tradeData[0].orders[1].price;

        vm.expectEmit(false, false, false, true);
        emit Sweep(_buyer);
        aggregator.execute{value: value + 0.1 ether}(tokenTransfers, tradeData, _buyer, _buyer, false);

        assertEq(IERC721(MULTIFACET_NFT).balanceOf(_buyer), 3);
        assertEq(IERC721(MULTIFACET_NFT).ownerOf(2828266), _buyer);
        assertEq(IERC721(MULTIFACET_NFT).ownerOf(2828267), _buyer);
        assertEq(IERC721(MULTIFACET_NFT).ownerOf(2828268), _buyer);
        assertEq(_buyer.balance, 200 ether - value);
        assertEq(address(NFT_OWNER).balance, 200 ether + (value * 9_800) / 10_000);
    }

    function testExecuteZeroOrders() public asPrankedUser(_buyer) {
        BasicOrder[] memory orders = new BasicOrder[](0);
        bytes[] memory ordersExtraData = new bytes[](0);

        TokenTransfer[] memory tokenTransfers = new TokenTransfer[](0);

        ILooksRareAggregator.TradeData[] memory tradeData = new ILooksRareAggregator.TradeData[](1);
        tradeData[0] = ILooksRareAggregator.TradeData({
            proxy: address(looksRareV2Proxy),
            selector: LooksRareV2Proxy.execute.selector,
            orders: orders,
            ordersExtraData: ordersExtraData,
            extraData: abi.encode(address(0)) // affiliate
        });

        vm.expectRevert(InvalidOrderLength.selector);
        aggregator.execute{value: 0}(tokenTransfers, tradeData, _buyer, _buyer, true);
    }

    function testExecuteOrdersLengthMismatch() public asPrankedUser(_buyer) {
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

        TokenTransfer[] memory tokenTransfers = new TokenTransfer[](0);

        uint256 value = orders[0].price + orders[1].price;

        ILooksRareAggregator.TradeData[] memory tradeData = new ILooksRareAggregator.TradeData[](1);
        tradeData[0] = ILooksRareAggregator.TradeData({
            proxy: address(looksRareV2Proxy),
            selector: LooksRareV2Proxy.execute.selector,
            orders: orders,
            ordersExtraData: ordersExtraData,
            extraData: abi.encode(address(0)) // affiliate
        });

        vm.expectRevert(InvalidOrderLength.selector);
        aggregator.execute{value: value}(tokenTransfers, tradeData, _buyer, _buyer, true);
    }

    function _testExecuteERC721(bool isAtomic) private {
        ILooksRareAggregator.TradeData[] memory tradeData = _generateERC721TradeData();
        TokenTransfer[] memory tokenTransfers = new TokenTransfer[](0);

        uint256 value = tradeData[0].orders[0].price + tradeData[0].orders[1].price;

        vm.expectEmit(false, false, false, true);
        emit Sweep(_buyer);
        aggregator.execute{value: value}(tokenTransfers, tradeData, _buyer, _buyer, isAtomic);

        assertEq(IERC721(MULTIFACET_NFT).balanceOf(_buyer), 3);
        assertEq(IERC721(MULTIFACET_NFT).ownerOf(2828266), _buyer);
        assertEq(IERC721(MULTIFACET_NFT).ownerOf(2828267), _buyer);
        assertEq(IERC721(MULTIFACET_NFT).ownerOf(2828268), _buyer);
        assertEq(_buyer.balance, 200 ether - value);
        assertEq(address(NFT_OWNER).balance, 200 ether + (value * 9_800) / 10_000);
    }

    function _testExecuteERC1155(bool isAtomic) private {
        ILooksRareAggregator.TradeData[] memory tradeData = _generateERC1155TradeData();
        TokenTransfer[] memory tokenTransfers = new TokenTransfer[](0);

        uint256 value = tradeData[0].orders[0].price + tradeData[0].orders[1].price;

        vm.expectEmit(false, false, false, true);
        emit Sweep(_buyer);
        aggregator.execute{value: value}(tokenTransfers, tradeData, _buyer, _buyer, isAtomic);

        assertEq(IERC1155(TEST_ERC1155).balanceOf(_buyer, 69), 5);
        assertEq(IERC1155(TEST_ERC1155).balanceOf(_buyer, 420), 5);
        assertEq(_buyer.balance, 200 ether - value);
        assertEq(address(NFT_OWNER).balance, 200 ether + (value * 9_800) / 10_000);
    }

    function _generateERC721TradeData() private view returns (ILooksRareAggregator.TradeData[] memory tradeData) {
        BasicOrder[] memory orders = validGoerliTestERC721Orders();
        MerkleTree memory merkleTree;

        bytes[] memory ordersExtraData = new bytes[](2);
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

        ordersExtraData[1] = abi.encode(
            LooksRareV2Proxy.OrderExtraData({
                merkleTree: merkleTree,
                globalNonce: 0,
                subsetNonce: 1,
                orderNonce: 1,
                strategyId: 0,
                price: orders[1].price,
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

    function _generateERC1155TradeData() private view returns (ILooksRareAggregator.TradeData[] memory tradeData) {
        BasicOrder[] memory orders = validGoerliTestERC1155Orders();
        MerkleTree memory merkleTree;

        bytes[] memory ordersExtraData = new bytes[](2);
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

        ordersExtraData[1] = abi.encode(
            LooksRareV2Proxy.OrderExtraData({
                merkleTree: merkleTree,
                globalNonce: 0,
                subsetNonce: 1,
                orderNonce: 1,
                strategyId: 0,
                price: orders[1].price,
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
