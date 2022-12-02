// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IERC20} from "@looksrare/contracts-libs/contracts/interfaces/generic/IERC20.sol";
import {IERC721} from "@looksrare/contracts-libs/contracts/interfaces/generic/IERC721.sol";
import {OwnableTwoSteps} from "@looksrare/contracts-libs/contracts/OwnableTwoSteps.sol";
import {SeaportProxy} from "../../contracts/proxies/SeaportProxy.sol";
import {ERC20EnabledLooksRareAggregator} from "../../contracts/ERC20EnabledLooksRareAggregator.sol";
import {LooksRareAggregator} from "../../contracts/LooksRareAggregator.sol";
import {IProxy} from "../../contracts/interfaces/IProxy.sol";
import {ILooksRareAggregator} from "../../contracts/interfaces/ILooksRareAggregator.sol";
import {IAllowanceTransfer} from "../../contracts/interfaces/IAllowanceTransfer.sol";
import {BasicOrder, TokenTransfer} from "../../contracts/libraries/OrderStructs.sol";
import {TestHelpers} from "./TestHelpers.sol";
import {TestParameters} from "./TestParameters.sol";
import {SeaportProxyTestHelpers} from "./SeaportProxyTestHelpers.sol";

/**
 * @notice SeaportProxy ERC721 USDC orders tests
 */
contract SeaportProxyERC721USDCTest is TestParameters, TestHelpers, SeaportProxyTestHelpers {
    LooksRareAggregator private aggregator;
    ERC20EnabledLooksRareAggregator private erc20EnabledAggregator;
    SeaportProxy private seaportProxy;
    address private constant PERMIT2 = 0x000000000022D473030F116dDEE9F6B43aC78BA3;

    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("mainnet"), 15_491_323);

        aggregator = new LooksRareAggregator();
        erc20EnabledAggregator = new ERC20EnabledLooksRareAggregator(address(aggregator));
        seaportProxy = new SeaportProxy(SEAPORT, address(aggregator));
        aggregator.addFunction(address(seaportProxy), SeaportProxy.execute.selector);

        deal(USDC, _buyer, INITIAL_USDC_BALANCE);

        aggregator.approve(USDC, SEAPORT, type(uint256).max);
        aggregator.setERC20EnabledLooksRareAggregator(address(erc20EnabledAggregator));
    }

    // function testExecuteAtomic() public {
    //     _testExecute(true);
    // }

    function testExecuteNonAtomic() public {
        _testExecute();
    }

    function _testExecute() private {
        uint256 fromPrivateKey = 0x12341234;
        address _buyer = vm.addr(fromPrivateKey);
        vm.startPrank(_buyer);

        ILooksRareAggregator.TradeData[] memory tradeData = _generateTradeData();
        uint256 totalPrice = tradeData[0].orders[0].price + tradeData[0].orders[1].price;
        // IERC20(USDC).approve(address(erc20EnabledAggregator), totalPrice);
        IERC20(USDC).approve(PERMIT2, totalPrice);

        TokenTransfer[] memory tokenTransfers = new TokenTransfer[](1);
        tokenTransfers[0].currency = USDC;
        tokenTransfers[0].amount = totalPrice;

        IAllowanceTransfer.PermitDetails memory details = IAllowanceTransfer.PermitDetails({
            token: USDC,
            amount: uint160(totalPrice),
            expiration: uint48(block.timestamp),
            nonce: 0
        });

        IAllowanceTransfer.PermitDetails[] memory batchDetails = new IAllowanceTransfer.PermitDetails[](1);
        batchDetails[0] = details;

        IAllowanceTransfer.PermitBatch memory permit = IAllowanceTransfer.PermitBatch({
            details: batchDetails,
            spender: address(this),
            sigDeadline: block.timestamp
        });

        bytes memory permitSignature = _getPermitSignature(permit);

        // erc20EnabledAggregator.execute(tokenTransfers, tradeData, _buyer, isAtomic);
        aggregator.execute(permit, permitSignature, tokenTransfers, tradeData, _buyer, _buyer, false);

        assertEq(IERC721(BAYC).balanceOf(_buyer), 2);
        assertEq(IERC721(BAYC).ownerOf(9948), _buyer);
        assertEq(IERC721(BAYC).ownerOf(8350), _buyer);
        assertEq(IERC20(USDC).balanceOf(_buyer), INITIAL_USDC_BALANCE - totalPrice);

        vm.stopPrank();
    }

    function _generateTradeData() private view returns (ILooksRareAggregator.TradeData[] memory) {
        BasicOrder memory orderOne = validBAYCId9948Order();
        BasicOrder memory orderTwo = validBAYCId8350Order();
        BasicOrder[] memory orders = new BasicOrder[](2);
        orders[0] = orderOne;
        orders[1] = orderTwo;

        bytes[] memory ordersExtraData = new bytes[](2);
        {
            bytes memory orderOneExtraData = validBAYCId9948OrderExtraData();
            bytes memory orderTwoExtraData = validBAYCId8350OrderExtraData();
            ordersExtraData[0] = orderOneExtraData;
            ordersExtraData[1] = orderTwoExtraData;
        }

        bytes memory extraData = validMultipleItemsSameCollectionExtraData();
        ILooksRareAggregator.TradeData[] memory tradeData = new ILooksRareAggregator.TradeData[](1);
        tradeData[0] = ILooksRareAggregator.TradeData({
            proxy: address(seaportProxy),
            selector: SeaportProxy.execute.selector,
            orders: orders,
            ordersExtraData: ordersExtraData,
            extraData: extraData
        });

        return tradeData;
    }

    function _getPermitSignature(IAllowanceTransfer.PermitBatch memory permit) private returns (bytes memory) {
        bytes32 domainSeparator = 0x866a5aba21966af95d6c7ab78eb2b2fc913915c28be3b9aa07cc04ff903e3f28;
        bytes32 _PERMIT_DETAILS_TYPEHASH = keccak256(
            "PermitDetails(address token,uint160 amount,uint48 expiration,uint48 nonce)"
        );
        bytes32 _PERMIT_BATCH_TYPEHASH = keccak256(
            "PermitBatch(PermitDetails[] details,address spender,uint256 sigDeadline)PermitDetails(address token,uint160 amount,uint48 expiration,uint48 nonce)"
        );

        bytes32[] memory permitHashes = new bytes32[](permit.details.length);
        for (uint256 i = 0; i < permit.details.length; ++i) {
            permitHashes[i] = keccak256(abi.encode(_PERMIT_DETAILS_TYPEHASH, permit.details[i]));
        }
        bytes32 msgHash = keccak256(
            abi.encodePacked(
                "\x19\x01",
                domainSeparator,
                keccak256(
                    abi.encode(
                        _PERMIT_BATCH_TYPEHASH,
                        keccak256(abi.encodePacked(permitHashes)),
                        permit.spender,
                        permit.sigDeadline
                    )
                )
            )
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(0x12341234, msgHash);
        return bytes.concat(r, s, bytes1(v));
    }
}
