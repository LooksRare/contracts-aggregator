// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {LooksRareProxy} from "./proxies/LooksRareProxy.sol";
import {BasicOrder, TokenTransfer} from "./libraries/OrderStructs.sol";
import {TokenRescuer} from "./TokenRescuer.sol";
import {TokenReceiver} from "./TokenReceiver.sol";
import {ILooksRareAggregator} from "./interfaces/ILooksRareAggregator.sol";
import {FeeData} from "./libraries/OrderStructs.sol";

/**
 * @title LooksRareAggregator
 * @notice This contract allows NFT sweepers to buy NFTs from different marketplaces
 *         by passing high-level structs + low-level bytes as calldata.
 * @author LooksRare protocol team (👀,💎)
 */
contract LooksRareAggregator is ILooksRareAggregator, TokenRescuer, TokenReceiver {
    /**
     * @notice Transactions that only involve ETH orders should be submitted to this contract
     *         directly. Transactions that involve ERC-20 orders should be submitted to the contract
     *         ERC20EnabledLooksRareAggregator and it will call this contract's execution function.
     *         The purpose is to prevent a malicious proxy from stealing users' ERC-20 tokens if
     *         this contract's ownership is compromised. By not providing any allowances to this
     *         aggregator, even if a malicious proxy is added, it cannot call
     *         token.transferFrom(victim, attacker, amount) inside the proxy within the context of the
     *         aggregator.
     */
    address public erc20EnabledLooksRareAggregator;
    mapping(address => mapping(bytes4 => bool)) private _proxyFunctionSelectors;
    mapping(address => FeeData) private _proxyFeeData;

    /**
     * @inheritdoc ILooksRareAggregator
     */
    function execute(
        TokenTransfer[] calldata tokenTransfers,
        TradeData[] calldata tradeData,
        address originator,
        address recipient,
        bool isAtomic
    ) external payable {
        if (recipient == address(0)) revert ZeroAddress();
        uint256 tradeDataLength = tradeData.length;
        if (tradeDataLength == 0) revert InvalidOrderLength();

        uint256 tokenTransfersLength = tokenTransfers.length;
        if (tokenTransfersLength == 0) {
            originator = msg.sender;
        } else if (msg.sender != erc20EnabledLooksRareAggregator) {
            revert UseERC20EnabledLooksRareAggregator();
        }

        for (uint256 i; i < tradeDataLength; ) {
            if (!_proxyFunctionSelectors[tradeData[i].proxy][tradeData[i].selector]) revert InvalidFunction();

            (bool success, bytes memory returnData) = tradeData[i].proxy.delegatecall(
                _encodeCalldata(tradeData[i], recipient, isAtomic)
            );

            if (!success) {
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

        if (tokenTransfersLength > 0) _returnERC20TokensIfAny(tokenTransfers, originator);
        // TODO: add this function to contracts-libs
        // _returnETHIfAny();
        assembly {
            if gt(selfbalance(), 0) {
                let status := call(gas(), originator, selfbalance(), 0, 0, 0, 0)
            }
        }

        emit Sweep(originator);
    }

    /**
     * @notice Enable making ERC-20 trades by setting the ERC-20 enabled LooksRare aggregator
     * @dev Must be called by the current owner. It can only be set once to prevent
     *      a malicious aggregator from being set in case of an ownership compromise.
     * @param _erc20EnabledLooksRareAggregator The ERC-20 enabled LooksRare aggregator's address
     */
    function setERC20EnabledLooksRareAggregator(address _erc20EnabledLooksRareAggregator) external onlyOwner {
        if (erc20EnabledLooksRareAggregator != address(0)) revert AlreadySet();
        erc20EnabledLooksRareAggregator = _erc20EnabledLooksRareAggregator;
        emit ERC20EnabledLooksRareAggregatorSet();
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
        uint256 tokenTransfersLength = tokenTransfers.length;
        for (uint256 i; i < tokenTransfersLength; ) {
            _executeERC20TransferFrom(tokenTransfers[i].currency, source, address(this), tokenTransfers[i].amount);
            unchecked {
                ++i;
            }
        }
    }

    function _returnERC20TokensIfAny(TokenTransfer[] calldata tokenTransfers, address recipient) private {
        uint256 tokenTransfersLength = tokenTransfers.length;
        for (uint256 i; i < tokenTransfersLength; ) {
            uint256 balance = IERC20(tokenTransfers[i].currency).balanceOf(address(this));
            if (balance > 0) _executeERC20DirectTransfer(tokenTransfers[i].currency, recipient, balance);

            unchecked {
                ++i;
            }
        }
    }
}
