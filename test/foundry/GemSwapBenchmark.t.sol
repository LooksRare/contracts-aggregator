// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {SeaportProxy} from "../../contracts/proxies/SeaportProxy.sol";
import {LooksRareProxy} from "../../contracts/proxies/LooksRareProxy.sol";
import {LooksRareAggregator} from "../../contracts/LooksRareAggregator.sol";
import {ILooksRareAggregator} from "../../contracts/interfaces/ILooksRareAggregator.sol";
// import {SeaportInterface} from "../../contracts/interfaces/SeaportInterface.sol";
// import {IProxy} from "../../contracts/proxies/IProxy.sol";
import {BasicOrder, TokenTransfer} from "../../contracts/libraries/OrderStructs.sol";
import {TestHelpers} from "./TestHelpers.sol";
import {SeaportProxyTestHelpers} from "./SeaportProxyTestHelpers.sol";
import {LooksRareProxyTestHelpers} from "./LooksRareProxyTestHelpers.sol";
// import {BasicOrderParameters, AdditionalRecipient, AdvancedOrder, OrderParameters, OfferItem, ConsiderationItem, CriteriaResolver} from "../../contracts/libraries/seaport/ConsiderationStructs.sol";
// import {BasicOrderType, OrderType, ItemType} from "../../contracts/libraries/seaport/ConsiderationEnums.sol";
import {IGemSwap} from "./utils/IGemSwap.sol";

abstract contract TestParameters {
    // address internal constant BAYC = 0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D;
    address internal constant GEMSWAP = 0x83C8F28c26bF6aaca652Df1DbBE0e1b56F8baBa2;
    address internal constant LOOKSRARE_V1 = 0x59728544B08AB483533076417FbBB2fD0B17CE3a;
    address internal constant LOOKSRARE_STRATEGY_FIXED_PRICE = 0x56244Bb70CbD3EA9Dc8007399F61dFC065190031;
    address internal constant SEAPORT = 0x00000000006c3852cbEf3e08E8dF289169EdE581;
    // I just picked an address with high ETH balance
    address internal constant _buyer = 0xbF3aEB96e164ae67E763D9e050FF124e7c3Fdd28;
}

contract GemSwapBenchmarkTest is TestParameters, TestHelpers, SeaportProxyTestHelpers, LooksRareProxyTestHelpers {
    IERC721 private bayc;

    function setUp() public {
        bayc = IERC721(BAYC);
    }

    function testBuyFromGemSwap() public {
        IGemSwap gemswap = IGemSwap(GEMSWAP);
        // calldata copied from impersonator.xyz
        IGemSwap.TradeDetails[] memory tradeDetails = new IGemSwap.TradeDetails[](2);
        tradeDetails[0].marketId = 18;
        tradeDetails[0].value = 72.69 ether;
        tradeDetails[0]
            .tradeData = hex"540616370000000000000000000000000000000000000000000000000000000000000040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000e000000000000000000000000000000000000000000000000000000000000006e0000000000000000000000000000000000000000000000000000000000000070000000000000000000000000000000000000000000000000000000000000007a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000003f0c6c1df332500000000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000a000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000052000000000000000000000000000000000000000000000000000000000000005a00000000000000000000000002ce485fe158593b9f3d4b840f1e44e3b77c96741000000000000000000000000004c00500000ad104d7dbd00e3ae0a5c00560c00000000000000000000000000000000000000000000000000000000000000016000000000000000000000000000000000000000000000000000000000000002200000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000006319fc0c00000000000000000000000000000000000000000000000000000000633f47b4000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000681f8d5fd259040000007b02230091a7ed01230072f7006a004d60a8d4e71d599b8104250f0000000000000000000000000000000000000000000000000000000000000000000300000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000002000000000000000000000000bc4ca0eda7647a8ab7c2061c2e118a18a936f13d0000000000000000000000000000000000000000000000000000000000002505000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000003000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003be566b60d6fcc000000000000000000000000000000000000000000000000003be566b60d6fcc0000000000000000000000000002ce485fe158593b9f3d4b840f1e44e3b77c9674100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000019382b3f2e14200000000000000000000000000000000000000000000000000019382b3f2e1420000000000000000000000000000000a26b00c1f0df003000390027140000faa71900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000019382b3f2e14200000000000000000000000000000000000000000000000000019382b3f2e142000000000000000000000000000a858ddc0445d8131dac4d1de01f834ffcba52ef10000000000000000000000000000000000000000000000000000000000000041f417064fb086c6e00d96a8a6045cf6b6349359e6646ec87d633d4b64afc0a09401b612068a34a5fa1d5c3149dc432988312d881b60d9adbacceeb76135ad69621b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000c00000000000000000000000000000000000000000000000000000000000000120000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002";
        tradeDetails[1].marketId = 16;
        tradeDetails[1].value = 73.88 ether;
        tradeDetails[1]
            .tradeData = hex"f3e816230000000000000000000000000000000000000000000000000000000000000040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000004014a7c9125dc0000000000000000000000000000000000000000000000000000000000000000250b0000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000035c00000000000000000000000000000000000000000000000000000000631a8a40000000000000000000000000000000000000000000000000000000006323c4bc000000000000000000000000000000000000000000000000000000000000254e000000000000000000000000000000000000000000000000000000000000001c137b835f53750e28c2ca2c14686206fc1b5e44b47b22f619ae35ac7e661de1fa2d22c786fd897ad08ae30113d1a8804e2313b6410438ba9187e14e94ef25e46700000000000000000000000017331428346e388f32013e6bec0aba29303857fd000000000000000000000000bc4ca0eda7647a8ab7c2061c2e118a18a936f13d";

        vm.prank(_buyer);
        uint256 gasRemaining = gasleft();
        gemswap.batchBuyWithETH{value: 146.57 ether}(tradeDetails);
        uint256 gasConsumed = gasRemaining - gasleft();

        emit log_named_uint("GemSwap consumed: ", gasConsumed);

        assertEq(bayc.balanceOf(_buyer), 2);
        assertEq(bayc.ownerOf(9477), _buyer);
        assertEq(bayc.ownerOf(9483), _buyer);
    }

    function testBuyFromLooksRareAggregatorAtomic() public {
        _testBuyFromLooksRareAggregator(true);
    }

    function testBuyFromLooksRareAggregatorNonAtomic() public {
        _testBuyFromLooksRareAggregator(false);
    }

    function _testBuyFromLooksRareAggregator(bool isAtomic) private {
        LooksRareAggregator aggregator = new LooksRareAggregator();

        SeaportProxy seaportProxy = new SeaportProxy(SEAPORT);
        aggregator.addFunction(address(seaportProxy), SeaportProxy.execute.selector);

        LooksRareProxy looksRareProxy = new LooksRareProxy(LOOKSRARE_V1);
        aggregator.addFunction(address(looksRareProxy), LooksRareProxy.execute.selector);

        ILooksRareAggregator.TradeData[] memory tradeData = new ILooksRareAggregator.TradeData[](2);
        TokenTransfer[] memory tokenTransfers = new TokenTransfer[](0);

        {
            BasicOrder[] memory seaportOrders = new BasicOrder[](1);
            seaportOrders[0] = validBAYCId9477Order();

            bytes[] memory seaportOrdersExtraData = new bytes[](1);
            seaportOrdersExtraData[0] = validBAYCId9477OrderExtraData();

            tradeData[0] = ILooksRareAggregator.TradeData({
                proxy: address(seaportProxy),
                selector: SeaportProxy.execute.selector,
                value: seaportOrders[0].price,
                orders: seaportOrders,
                ordersExtraData: seaportOrdersExtraData,
                extraData: isAtomic ? validSingleBAYCExtraData() : new bytes(0),
                tokenTransfers: tokenTransfers
            });

            BasicOrder[] memory looksRareOrders = validBAYCId9483Order();
            bytes[] memory looksRareOrdersExtraData = new bytes[](1);
            looksRareOrdersExtraData[0] = abi.encode(
                looksRareOrders[0].price,
                9550,
                860,
                LOOKSRARE_STRATEGY_FIXED_PRICE
            );

            tradeData[1] = ILooksRareAggregator.TradeData({
                proxy: address(looksRareProxy),
                selector: LooksRareProxy.execute.selector,
                value: looksRareOrders[0].price,
                orders: looksRareOrders,
                ordersExtraData: looksRareOrdersExtraData,
                extraData: new bytes(0),
                tokenTransfers: tokenTransfers
            });
        }

        vm.prank(_buyer);
        uint256 gasRemaining = gasleft();
        aggregator.execute{value: 146.57 ether}(tokenTransfers, tradeData, _buyer, isAtomic);
        uint256 gasConsumed = gasRemaining - gasleft();

        emit log_named_uint("LooksRareAggregator consumed: ", gasConsumed);

        assertEq(bayc.balanceOf(_buyer), 2);
        assertEq(bayc.ownerOf(9477), _buyer);
        assertEq(bayc.ownerOf(9483), _buyer);
    }
}