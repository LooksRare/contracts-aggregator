// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {IX2Y2} from "../interfaces/IX2Y2.sol";
import {BasicOrder, TokenTransfer} from "../libraries/OrderStructs.sol";
import {Market} from "../libraries/x2y2/MarketConsts.sol";
import {SignatureChecker} from "@looksrare/contracts-libs/contracts/SignatureChecker.sol";
import {CollectionType} from "../libraries/OrderEnums.sol";
import {TokenReceiverProxy} from "./TokenReceiverProxy.sol";
import {TokenRescuer} from "../TokenRescuer.sol";
import {LowLevelETH} from "../lowLevelCallers/LowLevelETH.sol";

/**
 * @title X2Y2Proxy
 * @notice This contract allows NFT sweepers to batch buy NFTs from X2Y2Proxy
 *         by passing high-level structs + low-level bytes as calldata.
 * @author LooksRare protocol team (👀,💎)
 */
contract X2Y2Proxy is TokenReceiverProxy, TokenRescuer, SignatureChecker {
    IX2Y2 public immutable marketplace;

    struct OrderExtraData {
        uint256 salt; // An arbitrary source of entropy for the order (per trade)
        bytes itemData; // The data of the token to be traded (id, address, etc)
        uint256 inputSalt; // An arbitrary source of entropy for the order (for the whole order)
        uint256 inputDeadline; // order deadline
        address executionDelegate; // The contract to execute the trade
        uint8 inputV; // v parameter of the order signature signed by an authorized signer (not the seller)
        bytes32 inputR; // r parameter of the order signature signed by an authorized signer (not the seller)
        bytes32 inputS; // s parameter of the order signature signed by an authorized signer (not the seller)
        Market.Fee[] fees; // An array of sales proceeds recipient and the % for each of them
    }

    constructor(address _marketplace) {
        marketplace = IX2Y2(_marketplace);
    }

    /**
     * @notice Execute X2Y2 NFT sweeps in a single transaction
     * @dev The 4th argument extraData is not used
     * @param orders Orders to be executed by Seaport
     * @param ordersExtraData Extra data for each order
     * @param recipient The address to receive the purchased NFTs
     * @param isAtomic Flag to enable atomic trades (all or nothing) or partial trades
     * @return Whether at least 1 out of N trades succeeded
     */
    function execute(
        TokenTransfer[] calldata,
        BasicOrder[] calldata orders,
        bytes[] calldata ordersExtraData,
        bytes calldata,
        address recipient,
        bool isAtomic
    ) external payable override returns (bool) {
        if (recipient == address(0)) revert ZeroAddress();

        uint256 ordersLength = orders.length;
        if (ordersLength == 0 || ordersLength != ordersExtraData.length) revert InvalidOrderLength();

        uint256 executedCount;
        for (uint256 i; i < ordersLength; ) {
            OrderExtraData memory orderExtraData = abi.decode(ordersExtraData[i], (OrderExtraData));
            bool executed = _executeSingleOrder(orders[i], orderExtraData, recipient, isAtomic);
            if (executed) executedCount += 1;

            unchecked {
                ++i;
            }
        }

        _returnETHIfAny();

        return executedCount > 0;
    }

    function _executeSingleOrder(
        BasicOrder calldata order,
        OrderExtraData memory orderExtraData,
        address recipient,
        bool isAtomic
    ) private returns (bool executed) {
        Market.RunInput memory runInput;

        runInput.r = orderExtraData.inputR;
        runInput.s = orderExtraData.inputS;
        runInput.v = orderExtraData.inputV;

        // amountToEth and amountToWeth default is 0
        runInput.shared.salt = orderExtraData.inputSalt;
        runInput.shared.deadline = orderExtraData.inputDeadline;
        runInput.shared.user = address(this);
        // canFail default is false

        Market.Order[] memory x2y2Orders = new Market.Order[](1);
        x2y2Orders[0].salt = orderExtraData.salt;
        x2y2Orders[0].user = order.signer;
        x2y2Orders[0].network = block.chainid;
        x2y2Orders[0].intent = Market.INTENT_SELL;
        // X2Y2 enums start with INVALID so plus 1
        x2y2Orders[0].delegateType = uint256(order.collectionType) + 1;
        x2y2Orders[0].deadline = order.endTime;
        x2y2Orders[0].currency = order.currency;
        // dataMask default is 0 bytes
        x2y2Orders[0].signVersion = Market.SIGN_V1;

        Market.OrderItem[] memory items = new Market.OrderItem[](1);
        items[0].price = order.price;
        items[0].data = orderExtraData.itemData;
        x2y2Orders[0].items = items;

        runInput.orders = x2y2Orders;

        Market.SettleDetail[] memory settleDetails = new Market.SettleDetail[](1);
        settleDetails[0].op = Market.Op.COMPLETE_SELL_OFFER;
        // bidIncentivePct/aucMinIncrementPct/aucIncDurationSecs default is 0
        settleDetails[0].executionDelegate = orderExtraData.executionDelegate;
        // dataReplacement/orderIdx/itemIdx default is 0
        settleDetails[0].price = order.price;
        settleDetails[0].itemHash = _hashItem(runInput.orders[0], runInput.orders[0].items[0]);
        settleDetails[0].fees = orderExtraData.fees;
        runInput.details = settleDetails;

        (bytes32 r, bytes32 s, uint8 v) = _splitSignature(order.signature);
        runInput.orders[0].r = r;
        runInput.orders[0].s = s;
        runInput.orders[0].v = v;

        if (isAtomic) {
            marketplace.run{value: order.price}(runInput);
            _redirectTokenToRecipient(order, recipient);
            executed = true;
        } else {
            try marketplace.run{value: order.price}(runInput) {
                _redirectTokenToRecipient(order, recipient);
                executed = true;
            } catch {}
        }
    }

    function _hashItem(Market.Order memory order, Market.OrderItem memory item) private pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    order.salt,
                    order.user,
                    order.network,
                    order.intent,
                    order.delegateType,
                    order.deadline,
                    order.currency,
                    order.dataMask,
                    item
                )
            );
    }

    /**
     * @dev Having this function helps solve stack too deep error
     */
    function _redirectTokenToRecipient(BasicOrder memory order, address recipient) private {
        _transferTokenToRecipient(
            order.collectionType,
            recipient,
            order.collection,
            order.tokenIds[0],
            order.amounts[0]
        );
    }
}
