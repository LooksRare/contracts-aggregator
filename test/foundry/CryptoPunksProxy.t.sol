// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import {CryptoPunksProxy} from "../../contracts/proxies/CryptoPunksProxy.sol";
import {TokenRescuer} from "../../contracts/TokenRescuer.sol";
import {IProxy} from "../../contracts/proxies/IProxy.sol";
import {BasicOrder, FeeData} from "../../contracts/libraries/OrderStructs.sol";
import {CollectionType} from "../../contracts/libraries/OrderEnums.sol";
import {TestHelpers} from "./TestHelpers.sol";
import {TokenRescuerTest} from "./TokenRescuer.t.sol";

abstract contract TestParameters {
    address internal constant CRYPTOPUNKS = 0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB;
    address internal constant _buyer = address(1);
    address internal constant _fakeAggregator = address(69420);
}

contract CryptoPunksProxyTest is TestParameters, TestHelpers, TokenRescuerTest {
    CryptoPunksProxy cryptoPunksProxy;
    TokenRescuer tokenRescuer;

    function setUp() public {
        cryptoPunksProxy = new CryptoPunksProxy(CRYPTOPUNKS, _fakeAggregator);
        tokenRescuer = TokenRescuer(address(cryptoPunksProxy));
        vm.deal(_buyer, 100 ether);
    }

    function testExecuteZeroOrders() public asPrankedUser(_buyer) {
        BasicOrder[] memory orders = new BasicOrder[](0);
        bytes[] memory ordersExtraData = new bytes[](0);

        vm.etch(address(_fakeAggregator), address(cryptoPunksProxy).code);
        vm.expectRevert(IProxy.InvalidOrderLength.selector);
        IProxy(_fakeAggregator).execute(orders, ordersExtraData, "", _buyer, false, 0, address(0));
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
        orders = new BasicOrder[](1);
        orders[0].signer = address(0);
        orders[0].collection = CRYPTOPUNKS;
        orders[0].collectionType = CollectionType.ERC721;

        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 3149;
        orders[0].tokenIds = tokenIds;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1;
        orders[0].amounts = amounts;

        orders[0].price = 68.5 ether;
        orders[0].currency = address(0);
        orders[0].startTime = 0;
        orders[0].endTime = 0;
        orders[0].signature = "";
    }
}
