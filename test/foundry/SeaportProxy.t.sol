pragma solidity 0.8.14;

import {OwnableTwoSteps} from "@looksrare/contracts-libs/contracts/OwnableTwoSteps.sol";
import {SeaportProxy} from "../../contracts/proxies/SeaportProxy.sol";
import {LooksRareAggregator} from "../../contracts/LooksRareAggregator.sol";
import {TokenRescuer} from "../../contracts/TokenRescuer.sol";
import {OrderType} from "../../contracts/libraries/seaport/ConsiderationEnums.sol";
import {AdditionalRecipient, Fulfillment, FulfillmentComponent} from "../../contracts/libraries/seaport/ConsiderationStructs.sol";
import {IProxy} from "../../contracts/proxies/IProxy.sol";
import {BasicOrder, TokenTransfer, FeeData} from "../../contracts/libraries/OrderStructs.sol";
import {CollectionType} from "../../contracts/libraries/OrderEnums.sol";
import {TestHelpers} from "./TestHelpers.sol";
import {TokenRescuerTest} from "./TokenRescuer.t.sol";
import {SeaportProxyTestHelpers} from "./SeaportProxyTestHelpers.sol";
import {MockERC20} from "./utils/MockERC20.sol";

abstract contract TestParameters {
    address internal constant SEAPORT = 0x00000000006c3852cbEf3e08E8dF289169EdE581;
    address internal constant BAYC = 0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D;
    address internal _buyer = address(1);
}

contract SeaportProxyTest is TestParameters, TestHelpers, TokenRescuerTest, SeaportProxyTestHelpers {
    LooksRareAggregator aggregator;
    SeaportProxy seaportProxy;
    TokenRescuer tokenRescuer;

    function setUp() public {
        aggregator = new LooksRareAggregator();
        seaportProxy = new SeaportProxy(SEAPORT, address(aggregator));
        tokenRescuer = TokenRescuer(address(seaportProxy));
        vm.deal(_buyer, 100 ether);
    }

    function testBuyWithETHZeroOrders() public asPrankedUser(_buyer) {
        BasicOrder[] memory orders = new BasicOrder[](0);
        bytes[] memory ordersExtraData = new bytes[](0);
        FeeData memory feeData;

        vm.expectRevert(IProxy.InvalidOrderLength.selector);
        seaportProxy.execute(orders, ordersExtraData, validSingleBAYCExtraData(), _buyer, false, feeData);
    }

    function testBuyWithETHOrdersLengthMismatch() public asPrankedUser(_buyer) {
        FeeData memory feeData;
        BasicOrder memory order = validBAYCId2518Order();
        BasicOrder[] memory orders = new BasicOrder[](1);
        orders[0] = order;

        bytes[] memory ordersExtraData = new bytes[](2);
        ordersExtraData[0] = validBAYCId2518OrderExtraData();
        ordersExtraData[1] = validBAYCId8498OrderExtraData();

        vm.expectRevert(IProxy.InvalidOrderLength.selector);
        seaportProxy.execute{value: orders[0].price}(
            orders,
            ordersExtraData,
            validSingleBAYCExtraData(),
            _buyer,
            false,
            feeData
        );
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
}
