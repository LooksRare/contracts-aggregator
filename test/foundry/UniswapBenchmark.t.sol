// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IERC721} from "@looksrare/contracts-libs/contracts/interfaces/generic/IERC721.sol";
import {IERC1155} from "@looksrare/contracts-libs/contracts/interfaces/generic/IERC1155.sol";
import {ILooksRareAggregator} from "../../contracts/interfaces/ILooksRareAggregator.sol";
import {LooksRareAggregator} from "../../contracts/LooksRareAggregator.sol";
import {LooksRareProxy} from "../../contracts/proxies/LooksRareProxy.sol";
import {IUniversalRouter} from "../../contracts/interfaces/IUniversalRouter.sol";
import {BasicOrder, TokenTransfer} from "../../contracts/libraries/OrderStructs.sol";
import {TestHelpers} from "./TestHelpers.sol";
import {TestParameters} from "./TestParameters.sol";
import {SeaportProxyTestHelpers} from "./SeaportProxyTestHelpers.sol";
import {LooksRareProxyTestHelpers} from "./LooksRareProxyTestHelpers.sol";

/**
 * @notice Gas benchmark against Uniswap
 */
contract UniswapBenchmarkTest is TestParameters, TestHelpers, SeaportProxyTestHelpers, LooksRareProxyTestHelpers {
    address private constant ALICE = 0xF977814e90dA44bFA03b6295A0616a897441aceC;
    IERC721 private constant COVEN = IERC721(0x5180db8F5c931aaE63c74266b211F580155ecac8);
    IERC1155 private constant TWERKY = IERC1155(0xf4680c917A873E2dd6eAd72f9f433e74EB9c623C);
    IUniversalRouter private constant UNIVERSAL_ROUTER = IUniversalRouter(0x0000000052BE00bA3a005edbE83a0fB9aaDB964C);

    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("mainnet"), 16_096_348);
    }

    function testBuyERC721FromLooksRareThroughUniswap() public {
        bytes[] memory inputs = new bytes[](1);
        inputs[
            0
        ] = hex"00000000000000000000000000000000000000000000000002847656c241800000000000000000000000000000000000000000000000000000000000000000a0000000000000000000000000f977814e90da44bfa03b6295a0616a897441acec0000000000000000000000005180db8f5c931aae63c74266b211f580155ecac800000000000000000000000000000000000000000000000000000000000004dc0000000000000000000000000000000000000000000000000000000000000344b4e4b2960000000000000000000000000000000000000000000000000000000000000040000000000000000000000000000000000000000000000000000000000000012000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000052be00ba3a005edbe83a0fb9aadb964c00000000000000000000000000000000000000000000000002847656c241800000000000000000000000000000000000000000000000000000000000000004dc000000000000000000000000000000000000000000000000000000000000264800000000000000000000000000000000000000000000000000000000000000c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001000000000000000000000000fc27c589b33b7a52eb0a304d76c0544ca4b496e60000000000000000000000005180db8f5c931aae63c74266b211f580155ecac800000000000000000000000000000000000000000000000002847656c241800000000000000000000000000000000000000000000000000000000000000004dc0000000000000000000000000000000000000000000000000000000000000001000000000000000000000000579af6fd30bf83a5ac0d636bc619f98dbdeb930c000000000000000000000000c02aaa39b223fe8d0a0e5c4f27ead9083c756cc20000000000000000000000000000000000000000000000000000000000000061000000000000000000000000000000000000000000000000000000006371edf30000000000000000000000000000000000000000000000000000000063997af300000000000000000000000000000000000000000000000000000000000026480000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000001c08ae20d23fc4efda6ba409ab56a5619a9278c1edc75981a33166001cd9977b07728042faa31f8e945089361e97160af44406c557492d36dae053df3e6fd93f91000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000";

        vm.prank(ALICE);
        uint256 gasRemaining = gasleft();
        UNIVERSAL_ROUTER.execute{value: 0.1814 ether}(hex"11", inputs, 2_000_000_000);
        uint256 gasConsumed = gasRemaining - gasleft();

        emit log_named_uint("Uniswap consumed: ", gasConsumed);

        assertEq(COVEN.ownerOf(1244), ALICE);
        assertEq(COVEN.balanceOf(ALICE), 1);
    }

    function testBuyERC1155FromLooksRareThroughUniswap() public {
        bytes[] memory inputs = new bytes[](1);
        inputs[
            0
        ] = hex"00000000000000000000000000000000000000000000000001617eb90b26c00000000000000000000000000000000000000000000000000000000000000000c0000000000000000000000000f977814e90da44bfa03b6295a0616a897441acec000000000000000000000000f4680c917a873e2dd6ead72f9f433e74eb9c623c000000000000000000000000000000000000000000000000000000000000003f00000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000344b4e4b2960000000000000000000000000000000000000000000000000000000000000040000000000000000000000000000000000000000000000000000000000000012000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000052be00ba3a005edbe83a0fb9aadb964c00000000000000000000000000000000000000000000000001617eb90b26c000000000000000000000000000000000000000000000000000000000000000003f000000000000000000000000000000000000000000000000000000000000264800000000000000000000000000000000000000000000000000000000000000c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010000000000000000000000008d894500675c860d86619cc77742b8dca7ef74e2000000000000000000000000f4680c917a873e2dd6ead72f9f433e74eb9c623c00000000000000000000000000000000000000000000000001617eb90b26c000000000000000000000000000000000000000000000000000000000000000003f0000000000000000000000000000000000000000000000000000000000000001000000000000000000000000579af6fd30bf83a5ac0d636bc619f98dbdeb930c000000000000000000000000c02aaa39b223fe8d0a0e5c4f27ead9083c756cc200000000000000000000000000000000000000000000000000000000000001050000000000000000000000000000000000000000000000000000000063769762000000000000000000000000000000000000000000000000000000006463d74400000000000000000000000000000000000000000000000000000000000026480000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000001c3ea34f6e25acaeb57f2c043ee5d03213395919e09524d6c004f95f2917880bdc561af73fd982c5e1a1a8c96843a7a195a91a1e86f6952807161f01bba5708f8d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000";

        vm.prank(ALICE);
        uint256 gasRemaining = gasleft();
        UNIVERSAL_ROUTER.execute{value: 0.0995 ether}(hex"14", inputs, 2_000_000_000);
        uint256 gasConsumed = gasRemaining - gasleft();

        emit log_named_uint("Uniswap consumed: ", gasConsumed);

        assertEq(TWERKY.balanceOf(ALICE, 63), 1);
    }

    function testBuyERC721FromLooksRareThroughLooksRareAggregator() public {
        LooksRareAggregator aggregator = new LooksRareAggregator();

        LooksRareProxy looksRareProxy = new LooksRareProxy(LOOKSRARE_V1, address(aggregator));
        aggregator.addFunction(address(looksRareProxy), LooksRareProxy.execute.selector);

        ILooksRareAggregator.TradeData[] memory tradeData = new ILooksRareAggregator.TradeData[](1);
        TokenTransfer[] memory tokenTransfers = new TokenTransfer[](0);

        {
            BasicOrder[] memory looksRareOrders = new BasicOrder[](1);
            looksRareOrders[0] = validCryptoCoven1244Order();
            bytes[] memory looksRareOrdersExtraData = new bytes[](1);
            looksRareOrdersExtraData[0] = abi.encode(
                looksRareOrders[0].price,
                9_800,
                97,
                LOOKSRARE_STRATEGY_FIXED_PRICE_V1B
            );

            tradeData[0] = ILooksRareAggregator.TradeData({
                proxy: address(looksRareProxy),
                selector: LooksRareProxy.execute.selector,
                orders: looksRareOrders,
                ordersExtraData: looksRareOrdersExtraData,
                extraData: new bytes(0)
            });
        }

        vm.prank(ALICE);
        uint256 gasRemaining = gasleft();
        aggregator.execute{value: 0.1814 ether}(tokenTransfers, tradeData, ALICE, ALICE, false);
        uint256 gasConsumed = gasRemaining - gasleft();

        emit log_named_uint("LooksRareAggregator consumed: ", gasConsumed);

        assertEq(COVEN.ownerOf(1244), ALICE);
        assertEq(COVEN.balanceOf(ALICE), 1);
    }

    function testBuyERC1155FromLooksRareThroughLooksRareAggregator() public {
        LooksRareAggregator aggregator = new LooksRareAggregator();

        LooksRareProxy looksRareProxy = new LooksRareProxy(LOOKSRARE_V1, address(aggregator));
        aggregator.addFunction(address(looksRareProxy), LooksRareProxy.execute.selector);

        ILooksRareAggregator.TradeData[] memory tradeData = new ILooksRareAggregator.TradeData[](1);
        TokenTransfer[] memory tokenTransfers = new TokenTransfer[](0);

        {
            BasicOrder[] memory looksRareOrders = new BasicOrder[](1);
            looksRareOrders[0] = validTwerky63Order();
            bytes[] memory looksRareOrdersExtraData = new bytes[](1);
            looksRareOrdersExtraData[0] = abi.encode(
                looksRareOrders[0].price,
                9_800,
                261,
                LOOKSRARE_STRATEGY_FIXED_PRICE_V1B
            );

            tradeData[0] = ILooksRareAggregator.TradeData({
                proxy: address(looksRareProxy),
                selector: LooksRareProxy.execute.selector,
                orders: looksRareOrders,
                ordersExtraData: looksRareOrdersExtraData,
                extraData: new bytes(0)
            });
        }

        vm.prank(ALICE);
        uint256 gasRemaining = gasleft();
        aggregator.execute{value: 0.0995 ether}(tokenTransfers, tradeData, ALICE, ALICE, false);
        uint256 gasConsumed = gasRemaining - gasleft();

        emit log_named_uint("LooksRareAggregator consumed: ", gasConsumed);

        assertEq(TWERKY.balanceOf(ALICE, 63), 1);
    }
}
