// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {CryptoPunksProxy} from "../../contracts/proxies/CryptoPunksProxy.sol";
import {TokenRescuer} from "../../contracts/TokenRescuer.sol";
import {LooksRareAggregator} from "../../contracts/LooksRareAggregator.sol";
import {ICryptoPunks} from "../../contracts/interfaces/ICryptoPunks.sol";
import {ILooksRareAggregator} from "../../contracts/interfaces/ILooksRareAggregator.sol";
import {IProxy} from "../../contracts/interfaces/IProxy.sol";
import {BasicOrder, FeeData, TokenTransfer} from "../../contracts/libraries/OrderStructs.sol";
import {CollectionType} from "../../contracts/libraries/OrderEnums.sol";
import {TestHelpers} from "./TestHelpers.sol";
import {TestParameters} from "./TestParameters.sol";
import {TokenRescuerTest} from "./TokenRescuer.t.sol";

contract CryptoPunksProxyTest is TestParameters, TestHelpers, TokenRescuerTest {
    LooksRareAggregator private aggregator;
    CryptoPunksProxy private cryptoPunksProxy;
    TokenRescuer private tokenRescuer;

    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("mainnet"), 15_358_065);

        aggregator = new LooksRareAggregator();
        cryptoPunksProxy = new CryptoPunksProxy(CRYPTOPUNKS, address(aggregator));
        aggregator.addFunction(address(cryptoPunksProxy), CryptoPunksProxy.execute.selector);
        tokenRescuer = TokenRescuer(address(cryptoPunksProxy));
        vm.deal(_buyer, 138 ether);
        // Forking from mainnet and the deployed addresses might have balance
        vm.deal(address(aggregator), 1 wei);
        vm.deal(address(cryptoPunksProxy), 0);
    }

    function testExecuteAtomic() public asPrankedUser(_buyer) {
        _testExecute(true);
    }

    function testExecuteNonAtomic() public asPrankedUser(_buyer) {
        _testExecute(false);
    }

    function testExecuteAtomicFail() public asPrankedUser(_buyer) {
        ILooksRareAggregator.TradeData[] memory tradeData = _generateTradeData();
        TokenTransfer[] memory tokenTransfers = new TokenTransfer[](0);

        // Pay nothing for the second order
        tradeData[0].orders[1].price = 0;

        vm.expectRevert(ILooksRareAggregator.TradeExecutionFailed.selector);
        aggregator.execute{value: 68.5 ether}({
            tokenTransfers: tokenTransfers,
            tradeData: tradeData,
            originator: _buyer,
            recipient: _buyer,
            isAtomic: true
        });
    }

    function testExecutePartialSuccess() public asPrankedUser(_buyer) {
        ILooksRareAggregator.TradeData[] memory tradeData = _generateTradeData();
        TokenTransfer[] memory tokenTransfers = new TokenTransfer[](0);

        // Pay nothing for the second order
        tradeData[0].orders[1].price = 0;

        vm.expectEmit(true, true, false, false);
        emit Sweep(_buyer);

        aggregator.execute{value: 68.5 ether}({
            tokenTransfers: tokenTransfers,
            tradeData: tradeData,
            originator: _buyer,
            recipient: _buyer,
            isAtomic: false
        });

        assertEq(ICryptoPunks(CRYPTOPUNKS).balanceOf(_buyer), 1);
        assertEq(ICryptoPunks(CRYPTOPUNKS).punkIndexToAddress(3149), _buyer);
        assertEq(_buyer.balance, 69.5 ether);
    }

    function testExecuteZeroOrders() public asPrankedUser(_buyer) {
        BasicOrder[] memory orders = new BasicOrder[](0);
        bytes[] memory ordersExtraData = new bytes[](0);
        TokenTransfer[] memory tokenTransfers = new TokenTransfer[](0);

        ILooksRareAggregator.TradeData[] memory tradeData = new ILooksRareAggregator.TradeData[](1);
        tradeData[0] = ILooksRareAggregator.TradeData({
            proxy: address(cryptoPunksProxy),
            selector: CryptoPunksProxy.execute.selector,
            maxFeeBp: 0,
            orders: orders,
            ordersExtraData: ordersExtraData,
            extraData: ""
        });

        vm.expectRevert(IProxy.InvalidOrderLength.selector);
        aggregator.execute{value: 138 ether}({
            tokenTransfers: tokenTransfers,
            tradeData: tradeData,
            originator: _buyer,
            recipient: _buyer,
            isAtomic: true
        });
    }

    function testRescueETH() public {
        _testRescueETH(tokenRescuer);
    }

    function testRescueETHNotOwner() public {
        _testRescueETHNotOwner(tokenRescuer);
    }

    function testRescueETHInsufficientAmount() public {
        _testRescueETHInsufficientAmount(tokenRescuer);
    }

    function testRescueERC20() public {
        _testRescueERC20(tokenRescuer);
    }

    function testRescueERC20NotOwner() public {
        _testRescueERC20NotOwner(tokenRescuer);
    }

    function testRescueERC20InsufficientAmount() public {
        _testRescueERC20InsufficientAmount(tokenRescuer);
    }

    function validCryptoPunksOrder() private pure returns (BasicOrder[] memory orders) {
        orders = new BasicOrder[](2);

        orders[0].signer = address(0);
        orders[0].collection = CRYPTOPUNKS;
        orders[0].collectionType = CollectionType.ERC721;

        orders[1].signer = address(0);
        orders[1].collection = CRYPTOPUNKS;
        orders[1].collectionType = CollectionType.ERC721;

        uint256[] memory orderOneTokenIds = new uint256[](1);
        orderOneTokenIds[0] = 3149;
        orders[0].tokenIds = orderOneTokenIds;

        uint256[] memory orderTwoTokenIds = new uint256[](1);
        orderTwoTokenIds[0] = 2675;
        orders[1].tokenIds = orderTwoTokenIds;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1;
        orders[0].amounts = amounts;
        orders[1].amounts = amounts;

        orders[0].price = 68.5 ether;
        orders[0].currency = address(0);
        orders[0].startTime = 0;
        orders[0].endTime = 0;
        orders[0].signature = "";

        orders[1].price = 69.5 ether;
        orders[1].currency = address(0);
        orders[1].startTime = 0;
        orders[1].endTime = 0;
        orders[1].signature = "";
    }

    function _testExecute(bool isAtomic) private {
        ILooksRareAggregator.TradeData[] memory tradeData = _generateTradeData();
        TokenTransfer[] memory tokenTransfers = new TokenTransfer[](0);

        vm.expectEmit(true, true, false, false);
        emit Sweep(_buyer);

        aggregator.execute{value: 138 ether}({
            tokenTransfers: tokenTransfers,
            tradeData: tradeData,
            originator: _buyer,
            recipient: _buyer,
            isAtomic: isAtomic
        });

        assertEq(ICryptoPunks(CRYPTOPUNKS).balanceOf(_buyer), 2);
        assertEq(ICryptoPunks(CRYPTOPUNKS).punkIndexToAddress(3149), _buyer);
        assertEq(ICryptoPunks(CRYPTOPUNKS).punkIndexToAddress(2675), _buyer);
        assertEq(_buyer.balance, 0);
    }

    function _generateTradeData() private view returns (ILooksRareAggregator.TradeData[] memory tradeData) {
        bytes[] memory ordersExtraData = new bytes[](2);
        tradeData = new ILooksRareAggregator.TradeData[](1);
        tradeData[0] = ILooksRareAggregator.TradeData({
            proxy: address(cryptoPunksProxy),
            selector: CryptoPunksProxy.execute.selector,
            maxFeeBp: 0,
            orders: validCryptoPunksOrder(),
            ordersExtraData: ordersExtraData,
            extraData: ""
        });
    }
}
