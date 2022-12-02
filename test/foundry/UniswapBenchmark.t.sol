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

    function testBuyERC721FromSeaportThroughUniswap() public {
        bytes[] memory inputs = new bytes[](1);
        inputs[
            0
        ] = hex"000000000000000000000000000000000000000000000001c9f78d2893e4000000000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000684e7acab24000000000000000000000000000000000000000000000000000000000000008000000000000000000000000000000000000000000000000000000000000006600000007b02230091a7ed01230072f7006a004d60a8d4e71d599b8104250f0000000000000000000000000000f977814e90da44bfa03b6295a0616a897441acec00000000000000000000000000000000000000000000000000000000000000a000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000052000000000000000000000000000000000000000000000000000000000000005a00000000000000000000000000f1fcc9da5db6753c90fbeb46024c056516fbc17000000000000000000000000004c00500000ad104d7dbd00e3ae0a5c00560c000000000000000000000000000000000000000000000000000000000000000160000000000000000000000000000000000000000000000000000000000000022000000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000062c8c8590000000000000000000000000000000000000000000000000000000063b6246900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b2ac118e60420000007b02230091a7ed01230072f7006a004d60a8d4e71d599b8104250f00000000000000000000000000000000000000000000000000000000000000000003000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000020000000000000000000000005180db8f5c931aae63c74266b211f580155ecac8000000000000000000000000000000000000000000000000000000000000204f000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000003000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001a79e95c588cc8000000000000000000000000000000000000000000000000001a79e95c588cc80000000000000000000000000000f1fcc9da5db6753c90fbeb46024c056516fbc170000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b72fd2103b280000000000000000000000000000000000000000000000000000b72fd2103b280000000000000000000000000008de9c5a032463c561423387a9648c5c7bcc5bc9000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000016e5fa420765000000000000000000000000000000000000000000000000000016e5fa4207650000000000000000000000000000ac9d54ca08740a608b6c474e5ca07d51ca8117fa000000000000000000000000000000000000000000000000000000000000004158073c305ffa6daf8b6279050d9837d88040350a004efe3028fd6cda8aef41cd0819bb209b6ef3b3d6df717180677a3916c15ea669f8251471d3d39ee6abdac31b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000";

        vm.prank(ALICE);
        uint256 gasRemaining = gasleft();
        UNIVERSAL_ROUTER.execute{value: 33 ether}(hex"10", inputs, 2_000_000_000);
        uint256 gasConsumed = gasRemaining - gasleft();

        emit log_named_uint("Uniswap consumed: ", gasConsumed);

        assertEq(COVEN.ownerOf(8271), ALICE);
        assertEq(COVEN.balanceOf(ALICE), 1);
    }
}
