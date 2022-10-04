// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import {ERC20TransferManager} from "../../contracts/ERC20TransferManager.sol";
import {TokenTransfer} from "../../contracts/libraries/OrderStructs.sol";
import {MockERC20} from "./utils/MockERC20.sol";
import {TestHelpers} from "./TestHelpers.sol";

abstract contract TestParameters {
    address internal constant _fakeAggregator = address(1);
    address internal constant _buyer = address(2);
}

contract ERC20TransferManagerTest is TestParameters, TestHelpers {
    ERC20TransferManager private erc20TransferManager;
    MockERC20 private erc20;
    TokenTransfer[] private tokenTransfers;
    uint256 private constant amount = 1 ether;

    function setUp() public {
        erc20TransferManager = new ERC20TransferManager(_fakeAggregator);
        erc20 = new MockERC20();

        erc20.mint(_buyer, amount);
        tokenTransfers = new TokenTransfer[](1);
        tokenTransfers[0].amount = amount;
        tokenTransfers[0].currency = address(erc20);

        vm.prank(_buyer);
        erc20.approve(address(erc20TransferManager), amount);
    }

    function testPullERC20Tokens() public {
        vm.prank(_fakeAggregator);
        erc20TransferManager.pullERC20Tokens(tokenTransfers, _buyer);

        assertEq(erc20.balanceOf(_buyer), 0);
        assertEq(erc20.balanceOf(_fakeAggregator), amount);
    }

    function testPullERC20TokensInvalidCaller() public {
        vm.prank(_buyer);
        vm.expectRevert(ERC20TransferManager.InvalidCaller.selector);
        erc20TransferManager.pullERC20Tokens(tokenTransfers, _buyer);
    }
}
