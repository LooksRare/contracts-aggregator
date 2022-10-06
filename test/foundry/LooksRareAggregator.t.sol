// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import {LooksRareAggregator} from "../../contracts/LooksRareAggregator.sol";
import {LooksRareProxy} from "../../contracts/proxies/LooksRareProxy.sol";
import {TokenRescuer} from "../../contracts/TokenRescuer.sol";
import {ILooksRareAggregator} from "../../contracts/interfaces/ILooksRareAggregator.sol";
import {BasicOrder, TokenTransfer} from "../../contracts/libraries/OrderStructs.sol";
import {IOwnableTwoSteps} from "@looksrare/contracts-libs/contracts/interfaces/IOwnableTwoSteps.sol";
import {MockERC20} from "./utils/MockERC20.sol";
import {MockERC721} from "./utils/MockERC721.sol";
import {MockERC1155} from "./utils/MockERC1155.sol";
import {TestHelpers} from "./TestHelpers.sol";
import {TokenRescuerTest} from "./TokenRescuer.t.sol";

abstract contract TestParameters {
    address internal constant LOOKSRARE_V1 = 0x59728544B08AB483533076417FbBB2fD0B17CE3a;
    address internal constant _notOwner = address(1);
    address internal constant _buyer = address(2);
}

contract LooksRareAggregatorTest is TestParameters, TestHelpers, TokenRescuerTest, ILooksRareAggregator {
    LooksRareAggregator aggregator;
    LooksRareProxy looksRareProxy;
    TokenRescuer tokenRescuer;

    function setUp() public {
        aggregator = new LooksRareAggregator();
        tokenRescuer = TokenRescuer(address(aggregator));
        looksRareProxy = new LooksRareProxy(LOOKSRARE_V1, address(aggregator));
    }

    function testAddFunction() public {
        assertTrue(!aggregator.supportsProxyFunction(address(looksRareProxy), LooksRareProxy.execute.selector));
        vm.expectEmit(true, true, false, true);
        emit FunctionAdded(address(looksRareProxy), LooksRareProxy.execute.selector);
        aggregator.addFunction(address(looksRareProxy), LooksRareProxy.execute.selector);
        assertTrue(aggregator.supportsProxyFunction(address(looksRareProxy), LooksRareProxy.execute.selector));
    }

    function testAddFunctionNotOwner() public {
        vm.prank(_notOwner);
        vm.expectRevert(IOwnableTwoSteps.NotOwner.selector);
        aggregator.addFunction(address(looksRareProxy), LooksRareProxy.execute.selector);
    }

    function testRemoveFunction() public {
        assertTrue(!aggregator.supportsProxyFunction(address(looksRareProxy), LooksRareProxy.execute.selector));
        aggregator.addFunction(address(looksRareProxy), LooksRareProxy.execute.selector);
        assertTrue(aggregator.supportsProxyFunction(address(looksRareProxy), LooksRareProxy.execute.selector));

        vm.expectEmit(true, true, false, true);
        emit FunctionRemoved(address(looksRareProxy), LooksRareProxy.execute.selector);
        aggregator.removeFunction(address(looksRareProxy), LooksRareProxy.execute.selector);
        assertTrue(!aggregator.supportsProxyFunction(address(looksRareProxy), LooksRareProxy.execute.selector));
    }

    function testRemoveFunctionNotOwner() public {
        aggregator.addFunction(address(looksRareProxy), LooksRareProxy.execute.selector);

        vm.prank(_notOwner);
        vm.expectRevert(IOwnableTwoSteps.NotOwner.selector);
        aggregator.removeFunction(address(looksRareProxy), LooksRareProxy.execute.selector);
    }

    function testApprove() public {
        MockERC20 erc20 = new MockERC20();
        assertEq(erc20.allowance(address(aggregator), address(looksRareProxy)), 0);
        aggregator.approve(address(looksRareProxy), address(erc20));
        assertEq(erc20.allowance(address(aggregator), address(looksRareProxy)), type(uint256).max);
    }

    function testApproveNotOwner() public {
        MockERC20 erc20 = new MockERC20();
        vm.prank(_buyer);
        vm.expectRevert(IOwnableTwoSteps.NotOwner.selector);
        aggregator.approve(address(erc20), address(looksRareProxy));
    }

    function testRevoke() public {
        MockERC20 erc20 = new MockERC20();

        aggregator.approve(address(looksRareProxy), address(erc20));
        assertEq(erc20.allowance(address(aggregator), address(looksRareProxy)), type(uint256).max);

        aggregator.revoke(address(looksRareProxy), address(erc20));
        assertEq(erc20.allowance(address(aggregator), address(looksRareProxy)), 0);
    }

    function testRevokeNotOwner() public {
        MockERC20 erc20 = new MockERC20();
        vm.prank(_buyer);
        vm.expectRevert(IOwnableTwoSteps.NotOwner.selector);
        aggregator.revoke(address(looksRareProxy), address(erc20));
    }

    function testRescueETH() public {
        _testRescueETH(tokenRescuer);
    }

    function testRescueETHNotOwner() public {
        _testRescueETHNotOwner(tokenRescuer);
    }

    function testRescueERC20() public {
        _testRescueERC20(tokenRescuer);
    }

    function testRescueERC20NotOwner() public {
        _testRescueERC20NotOwner(tokenRescuer);
    }

    function testRescueERC721() public {
        MockERC721 mockERC721 = new MockERC721();
        mockERC721.mint(address(aggregator));
        aggregator.rescueERC721(address(mockERC721), luckyUser, 0);
        assertEq(mockERC721.balanceOf(address(luckyUser)), 1);
        assertEq(mockERC721.balanceOf(address(aggregator)), 0);
        assertEq(mockERC721.ownerOf(0), luckyUser);
    }

    function testRescueERC721NotOwner() public {
        MockERC721 mockERC721 = new MockERC721();
        mockERC721.mint(address(aggregator));
        vm.prank(luckyUser);
        vm.expectRevert(IOwnableTwoSteps.NotOwner.selector);
        aggregator.rescueERC721(address(mockERC721), luckyUser, 0);
        assertEq(mockERC721.balanceOf(address(luckyUser)), 0);
        assertEq(mockERC721.balanceOf(address(aggregator)), 1);
        assertEq(mockERC721.ownerOf(0), address(aggregator));
    }

    function testRescueERC1155() public {
        MockERC1155 mockERC1155 = new MockERC1155();
        mockERC1155.mint(address(aggregator), 0, 2, "");
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 0;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 2;
        aggregator.rescueERC1155(address(mockERC1155), luckyUser, tokenIds, amounts);
        assertEq(mockERC1155.balanceOf(address(luckyUser), 0), 2);
        assertEq(mockERC1155.balanceOf(address(aggregator), 0), 0);
    }

    function testRescueERC1155NotOwner() public {
        MockERC1155 mockERC1155 = new MockERC1155();
        mockERC1155.mint(address(aggregator), 0, 2, "");
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 0;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 2;
        vm.prank(luckyUser);
        vm.expectRevert(IOwnableTwoSteps.NotOwner.selector);
        aggregator.rescueERC1155(address(mockERC1155), luckyUser, tokenIds, amounts);
        assertEq(mockERC1155.balanceOf(address(luckyUser), 0), 0);
        assertEq(mockERC1155.balanceOf(address(aggregator), 0), 2);
    }

    function testBuyWithETHZeroOrders() public {
        TokenTransfer[] memory tokenTransfers = new TokenTransfer[](0);
        ILooksRareAggregator.TradeData[] memory tradeData = new ILooksRareAggregator.TradeData[](0);
        vm.expectRevert(ILooksRareAggregator.InvalidOrderLength.selector);
        aggregator.execute(tokenTransfers, tradeData, _buyer, false);
    }
}
