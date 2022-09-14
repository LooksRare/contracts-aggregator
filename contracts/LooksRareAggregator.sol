// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {LooksRareProxy} from "./proxies/LooksRareProxy.sol";
import {BasicOrder, TokenTransfer} from "./libraries/OrderStructs.sol";
import {TokenLogic} from "./TokenLogic.sol";
import {TokenReceiver} from "./TokenReceiver.sol";
import {ILooksRareAggregator} from "./interfaces/ILooksRareAggregator.sol";
import {FeeData} from "./libraries/OrderStructs.sol";

/**
 * @title LooksRareAggregator
 * @notice This contract allows NFT sweepers to buy NFTs from different marketplaces
 *         by passing high-level structs + low-level bytes as calldata.
 * @author LooksRare protocol team (👀,💎)
 */
contract LooksRareAggregator is TokenLogic, TokenReceiver, ILooksRareAggregator {
    mapping(address => mapping(bytes4 => bool)) private _proxyFunctionSelectors;
    mapping(address => FeeData) private _proxyFeeData;

    /**
     * @notice Execute NFT sweeps in different marketplaces in a single transaction
     * @param tokenTransfers Aggregated ERC-20 token transfers for all markets
     * @param tradeData Data object to be passed downstream to each marketplace's proxy for execution
     * @param recipient The address to receive the purchased NFTs
     * @param isAtomic Flag to enable atomic trades (all or nothing) or partial trades
     */
    function execute(
        TokenTransfer[] calldata tokenTransfers,
        TradeData[] calldata tradeData,
        address recipient,
        bool isAtomic
    ) external payable {
        if (recipient == address(0)) revert ZeroAddress();
        if (tradeData.length == 0) revert InvalidOrderLength();

        if (tokenTransfers.length > 0) _pullERC20Tokens(tokenTransfers, msg.sender);

        uint256 successCount;
        for (uint256 i; i < tradeData.length; ) {
            if (!_proxyFunctionSelectors[tradeData[i].proxy][tradeData[i].selector]) revert InvalidFunction();

            (bool success, bytes memory returnData) = tradeData[i].proxy.delegatecall(
                _encodeCalldata(tradeData[i], recipient, isAtomic)
            );

            if (success) {
                bool someExecuted = abi.decode(returnData, (bool));
                if (someExecuted) successCount += 1;
            } else {
                if (isAtomic) {
                    if (returnData.length > 0) {
                        assembly {
                            let returnDataSize := mload(returnData)
                            revert(add(32, returnData), returnDataSize)
                        }
                    } else {
                        revert TradeExecutionFailed();
                    }
                }
            }

            unchecked {
                ++i;
            }
        }

        if (tokenTransfers.length > 0) _returnERC20TokensIfAny(tokenTransfers, msg.sender);
        _returnETHIfAny();

        emit Sweep(msg.sender, tradeData.length, successCount);
    }

    /**
     * @notice Enable calling the specified proxy's trade function
     * @dev Must be called by the current owner
     * @param proxy The marketplace proxy's address
     * @param selector The marketplace proxy's function selector
     */
    function addFunction(address proxy, bytes4 selector) external onlyOwner {
        _proxyFunctionSelectors[proxy][selector] = true;
        emit FunctionAdded(proxy, selector);
    }

    /**
     * @notice Disable calling the specified proxy's trade function
     * @dev Must be called by the current owner
     * @param proxy The marketplace proxy's address
     * @param selector The marketplace proxy's function selector
     */
    function removeFunction(address proxy, bytes4 selector) external onlyOwner {
        delete _proxyFunctionSelectors[proxy][selector];
        emit FunctionRemoved(proxy, selector);
    }

    /**
     * @param proxy Proxy to apply the fee to
     * @param bp Fee basis point
     * @param recipient Fee recipient
     */
    function setFee(
        address proxy,
        uint16 bp,
        address recipient
    ) external onlyOwner {
        if (bp > 10000) revert FeeTooHigh();
        _proxyFeeData[proxy].bp = bp;
        _proxyFeeData[proxy].recipient = recipient;

        emit FeeUpdated(proxy, bp, recipient);
    }

    /**
     * @notice Approve marketplaces to transfer ERC-20 tokens from the aggregator
     * @param marketplace The address of the marketplace to approve
     * @param currency The address of the ERC-20 token to approve
     */
    function approve(address marketplace, address currency) external onlyOwner {
        IERC20(currency).approve(marketplace, type(uint256).max);
    }

    /**
     * @notice Revoke a marketplace's approval to transfer ERC-20 tokens from the aggregator
     * @param marketplace The address of the marketplace to revoke
     * @param currency The address of the ERC-20 token to revoke
     */
    function revoke(address marketplace, address currency) external onlyOwner {
        IERC20(currency).approve(marketplace, 0);
    }

    /**
     * @param proxy The marketplace proxy's address
     * @param selector The marketplace proxy's function selector
     * @return Whether the marketplace proxy's function can be called from the aggregator
     */
    function supportsProxyFunction(address proxy, bytes4 selector) external view returns (bool) {
        return _proxyFunctionSelectors[proxy][selector];
    }

    function _encodeCalldata(
        TradeData calldata singleTradeData,
        address recipient,
        bool isAtomic
    ) private view returns (bytes memory) {
        return
            abi.encodeWithSelector(
                singleTradeData.selector,
                singleTradeData.orders,
                singleTradeData.ordersExtraData,
                singleTradeData.extraData,
                recipient,
                isAtomic,
                _proxyFeeData[singleTradeData.proxy]
            );
    }

    receive() external payable {}

    function _pullERC20Tokens(TokenTransfer[] calldata tokenTransfers, address source) private {
        for (uint256 i; i < tokenTransfers.length; ) {
            _executeERC20Transfer(tokenTransfers[i].currency, source, address(this), tokenTransfers[i].amount);
            unchecked {
                ++i;
            }
        }
    }

    function _returnERC20TokensIfAny(TokenTransfer[] calldata tokenTransfers, address recipient) private {
        for (uint256 i; i < tokenTransfers.length; ) {
            uint256 balance = IERC20(tokenTransfers[i].currency).balanceOf(address(this));
            if (balance > 0) _executeERC20DirectTransfer(tokenTransfers[i].currency, recipient, balance);

            unchecked {
                ++i;
            }
        }
    }
}
