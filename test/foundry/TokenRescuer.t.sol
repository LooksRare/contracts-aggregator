// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import {LooksRareAggregator} from "../../contracts/LooksRareAggregator.sol";
import {TokenRescuer} from "../../contracts/TokenRescuer.sol";
import {OwnableTwoSteps} from "@looksrare/contracts-libs/contracts/OwnableTwoSteps.sol";
import {MockERC20} from "./utils/MockERC20.sol";
import {TestHelpers} from "./TestHelpers.sol";

abstract contract TestParameters {
    address internal constant luckyUser = address(69420);
    uint256 internal constant luckyNumber = 6.9420 ether;
}

contract TokenRescuerTest is TestParameters, TestHelpers {
    function _testRescueETH(TokenRescuer tokenRescuer) internal {
        vm.deal(address(tokenRescuer), luckyNumber);
        tokenRescuer.rescueETH(luckyUser);
        assertEq(address(luckyUser).balance, luckyNumber - 1);
        assertEq(address(tokenRescuer).balance, 1);
    }

    function _testRescueETHInsufficientAmount(TokenRescuer tokenRescuer) internal {
        vm.deal(address(tokenRescuer), 1);
        vm.expectRevert(TokenRescuer.InsufficientAmount.selector);
        tokenRescuer.rescueETH(luckyUser);
        assertEq(address(luckyUser).balance, 0);
        assertEq(address(tokenRescuer).balance, 1);
    }

    function _testRescueETHNotOwner(TokenRescuer tokenRescuer) internal {
        vm.deal(address(tokenRescuer), luckyNumber);
        vm.prank(luckyUser);
        vm.expectRevert(OwnableTwoSteps.NotOwner.selector);
        tokenRescuer.rescueETH(luckyUser);
        assertEq(address(luckyUser).balance, 0);
        assertEq(address(tokenRescuer).balance, luckyNumber);
    }

    function _testRescueERC20(TokenRescuer tokenRescuer) internal {
        MockERC20 mockERC20 = new MockERC20();
        mockERC20.mint(address(tokenRescuer), luckyNumber);
        tokenRescuer.rescueERC20(address(mockERC20), luckyUser);
        assertEq(mockERC20.balanceOf(address(luckyUser)), luckyNumber - 1);
        assertEq(mockERC20.balanceOf(address(tokenRescuer)), 1);
    }

    function _testRescueERC20NotOwner(TokenRescuer tokenRescuer) internal {
        MockERC20 mockERC20 = new MockERC20();
        mockERC20.mint(address(tokenRescuer), luckyNumber);
        vm.prank(luckyUser);
        vm.expectRevert(OwnableTwoSteps.NotOwner.selector);
        tokenRescuer.rescueERC20(address(mockERC20), luckyUser);
        assertEq(mockERC20.balanceOf(address(luckyUser)), 0);
        assertEq(mockERC20.balanceOf(address(tokenRescuer)), luckyNumber);
    }

    function _testRescueERC20InsufficientAmount(TokenRescuer tokenRescuer) internal {
        MockERC20 mockERC20 = new MockERC20();
        mockERC20.mint(address(tokenRescuer), 1);
        vm.expectRevert(TokenRescuer.InsufficientAmount.selector);
        tokenRescuer.rescueERC20(address(mockERC20), luckyUser);
        assertEq(mockERC20.balanceOf(address(luckyUser)), 0);
        assertEq(mockERC20.balanceOf(address(tokenRescuer)), 1);
    }
}
