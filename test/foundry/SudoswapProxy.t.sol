// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import {SudoswapProxy} from "../../contracts/proxies/SudoswapProxy.sol";
import {TokenLogic} from "../../contracts/TokenLogic.sol";
import {IProxy} from "../../contracts/proxies/IProxy.sol";
import {BasicOrder, TokenTransfer} from "../../contracts/libraries/OrderStructs.sol";
import {CollectionType} from "../../contracts/libraries/OrderEnums.sol";
import {TestHelpers} from "./TestHelpers.sol";
import {TokenLogicTest} from "./TokenLogic.t.sol";

abstract contract TestParameters {
    address internal constant SUDOSWAP = 0x2B2e8cDA09bBA9660dCA5cB6233787738Ad68329;
    address internal constant MOODIE = 0x0F23939EE95350F26D9C1B818Ee0Cc1C8Fd2b99D;
    address internal _buyer = address(1);
}

contract SudoswapProxyTest is TestParameters, TestHelpers, TokenLogicTest {
    SudoswapProxy sudoswapProxy;
    TokenLogic tokenRescuer;

    function setUp() public {
        sudoswapProxy = new SudoswapProxy(SUDOSWAP);
        tokenRescuer = TokenLogic(address(sudoswapProxy));
        vm.deal(_buyer, 100 ether);
    }

    function testBuyWithETHZeroOrders() public asPrankedUser(_buyer) {
        TokenTransfer[] memory tokenTransfers = new TokenTransfer[](0);
        BasicOrder[] memory orders = new BasicOrder[](0);
        bytes[] memory ordersExtraData = new bytes[](0);

        vm.expectRevert(IProxy.InvalidOrderLength.selector);
        sudoswapProxy.execute(tokenTransfers, orders, ordersExtraData, "", _buyer, false);
    }

    function testBuyWithETHOrdersRecipientZeroAddress() public {
        TokenTransfer[] memory tokenTransfers = new TokenTransfer[](0);
        BasicOrder[] memory orders = validMoodieOrder();
        bytes[] memory ordersExtraData = new bytes[](0);

        vm.expectRevert(IProxy.ZeroAddress.selector);
        sudoswapProxy.execute{value: orders[0].price}(tokenTransfers, orders, ordersExtraData, "", address(0), false);
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

    function validMoodieOrder() private pure returns (BasicOrder[] memory orders) {
        orders = new BasicOrder[](1);
        orders[0].signer = address(0);
        orders[0].collection = MOODIE;
        orders[0].collectionType = CollectionType.ERC721;

        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 5536;
        orders[0].tokenIds = tokenIds;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1;
        orders[0].amounts = amounts;

        orders[0].price = 221649999999999993;
        orders[0].currency = address(0);
        orders[0].startTime = 0;
        orders[0].endTime = 0;
        orders[0].signature = "";
    }
}
