// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ReentrancyGuard} from "@looksrare/contracts-libs/contracts/ReentrancyGuard.sol";
import {LowLevelERC20Approve} from "@looksrare/contracts-libs/contracts/lowLevelCallers/LowLevelERC20Approve.sol";
import {LowLevelERC721Transfer} from "@looksrare/contracts-libs/contracts/lowLevelCallers/LowLevelERC721Transfer.sol";
import {LowLevelERC1155Transfer} from "@looksrare/contracts-libs/contracts/lowLevelCallers/LowLevelERC1155Transfer.sol";
import {IERC20} from "@looksrare/contracts-libs/contracts/interfaces/generic/IERC20.sol";
import {TokenRescuer} from "./TokenRescuer.sol";
import {TokenReceiver} from "./TokenReceiver.sol";
import {ILooksRareAggregator} from "./interfaces/ILooksRareAggregator.sol";
import {FeeData, TokenTransfer} from "./libraries/OrderStructs.sol";

/**
 * @title LooksRareAggregator
 * @notice This contract allows NFT sweepers to buy NFTs from
 *         different marketplaces by passing high-level structs
 *         + low-level bytes as calldata.
 * @author LooksRare protocol team (👀,💎)
 */
contract LooksRareAggregator is
    ILooksRareAggregator,
    TokenRescuer,
    TokenReceiver,
    ReentrancyGuard,
    LowLevelERC20Approve,
    LowLevelERC721Transfer,
    LowLevelERC1155Transfer
{
    /**
     * @notice Transactions that only involve ETH orders should be submitted to
     *         this contract directly. Transactions that involve ERC20 orders
     *         should be submitted to the contract ERC20EnabledLooksRareAggregator
     *         and it will call this contract's execution function. The purpose
     *         is to prevent a malicious proxy from stealing users' ERC20 tokens
     *         if this contract's ownership is compromised. By not providing any
     *         allowances to this aggregator, even if a malicious proxy is added,
     *         it cannot call token.transferFrom(victim, attacker, amount) inside
     *         the proxy within the context of the aggregator.
     */
    address public erc20EnabledLooksRareAggregator;
    mapping(address => mapping(bytes4 => uint256)) private _proxyFunctionSelectors;
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
    ) external payable nonReentrant {
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
            TradeData calldata singleTradeData = tradeData[i];
            if (_proxyFunctionSelectors[singleTradeData.proxy][singleTradeData.selector] != 1) revert InvalidFunction();

            (bytes memory proxyCalldata, bool maxFeeBpViolated) = _encodeCalldataAndValidateFeeBp(
                singleTradeData,
                recipient,
                isAtomic
            );
            if (maxFeeBpViolated) {
                if (isAtomic) {
                    revert FeeTooHigh();
                } else {
                    unchecked {
                        ++i;
                    }
                    continue;
                }
            }
            (bool success, bytes memory returnData) = singleTradeData.proxy.delegatecall(proxyCalldata);

            if (!success) {
                if (isAtomic) {
                    if (returnData.length != 0) {
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

        if (tokenTransfersLength != 0) _returnERC20TokensIfAny(tokenTransfers, originator);
        assembly {
            if gt(selfbalance(), 1) {
                let status := call(gas(), originator, sub(selfbalance(), 1), 0, 0, 0, 0)
            }
        }

        emit Sweep(originator);
    }

    /**
     * @notice Enable making ERC20 trades by setting the ERC20 enabled LooksRare aggregator
     * @dev Must be called by the current owner. It can only be set once to prevent
     *      a malicious aggregator from being set in case of an ownership compromise.
     * @param _erc20EnabledLooksRareAggregator The ERC20 enabled LooksRare aggregator's address
     */
    function setERC20EnabledLooksRareAggregator(address _erc20EnabledLooksRareAggregator) external onlyOwner {
        if (erc20EnabledLooksRareAggregator != address(0)) revert AlreadySet();
        erc20EnabledLooksRareAggregator = _erc20EnabledLooksRareAggregator;
    }

    /**
     * @notice Enable calling the specified proxy's trade function
     * @dev Must be called by the current owner
     * @param proxy The marketplace proxy's address
     * @param selector The marketplace proxy's function selector
     */
    function addFunction(address proxy, bytes4 selector) external onlyOwner {
        _proxyFunctionSelectors[proxy][selector] = 1;
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
        uint256 bp,
        address recipient
    ) external onlyOwner {
        if (bp > 10_000) revert FeeTooHigh();
        _proxyFeeData[proxy].bp = bp;
        _proxyFeeData[proxy].recipient = recipient;

        emit FeeUpdated(proxy, bp, recipient);
    }

    /**
     * @notice Approve marketplaces to transfer ERC20 tokens from the aggregator
     * @param currency The ERC20 token address to approve
     * @param marketplace The marketplace address to approve
     * @param amount The amount of ERC20 token to approve
     */
    function approve(
        address currency,
        address marketplace,
        uint256 amount
    ) external onlyOwner {
        _executeERC20Approve(currency, marketplace, amount);
    }

    /**
     * @param proxy The marketplace proxy's address
     * @param selector The marketplace proxy's function selector
     * @return Whether the marketplace proxy's function can be called from the aggregator
     */
    function supportsProxyFunction(address proxy, bytes4 selector) external view returns (bool) {
        return _proxyFunctionSelectors[proxy][selector] == 1;
    }

    /**
     * @notice Rescue any of the contract's trapped ERC721 tokens
     * @dev Must be called by the current owner
     * @param collection The address of the ERC721 token to rescue from the contract
     * @param tokenId The token ID of the ERC721 token to rescue from the contract
     * @param to Send the contract's specified ERC721 token ID to this address
     */
    function rescueERC721(
        address collection,
        address to,
        uint256 tokenId
    ) external onlyOwner {
        _executeERC721TransferFrom(collection, address(this), to, tokenId);
    }

    /**
     * @notice Rescue any of the contract's trapped ERC1155 tokens
     * @dev Must be called by the current owner
     * @param collection The address of the ERC1155 token to rescue from the contract
     * @param tokenIds The token IDs of the ERC1155 token to rescue from the contract
     * @param amounts The amount of each token ID to rescue
     * @param to Send the contract's specified ERC1155 token ID to this address
     */
    function rescueERC1155(
        address collection,
        address to,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts
    ) external onlyOwner {
        _executeERC1155SafeBatchTransferFrom(collection, address(this), to, tokenIds, amounts);
    }

    /**
     * @dev If any order fails, the ETH paid to the marketplace
     *      is refunded to the aggregator contract. The aggregator then has to refund
     *      the ETH back to the user through _returnETHIfAny.
     */
    receive() external payable {}

    function _encodeCalldataAndValidateFeeBp(
        TradeData calldata singleTradeData,
        address recipient,
        bool isAtomic
    ) private view returns (bytes memory proxyCalldata, bool maxFeeBpViolated) {
        FeeData memory feeData = _proxyFeeData[singleTradeData.proxy];
        maxFeeBpViolated = singleTradeData.maxFeeBp < feeData.bp;
        proxyCalldata = abi.encodeWithSelector(
            singleTradeData.selector,
            singleTradeData.orders,
            singleTradeData.ordersExtraData,
            singleTradeData.extraData,
            recipient,
            isAtomic,
            feeData.bp,
            feeData.recipient
        );
    }

    function _returnERC20TokensIfAny(TokenTransfer[] calldata tokenTransfers, address recipient) private {
        uint256 tokenTransfersLength = tokenTransfers.length;
        for (uint256 i; i < tokenTransfersLength; ) {
            uint256 balance = IERC20(tokenTransfers[i].currency).balanceOf(address(this));
            if (balance != 0) _executeERC20DirectTransfer(tokenTransfers[i].currency, recipient, balance);

            unchecked {
                ++i;
            }
        }
    }
}
