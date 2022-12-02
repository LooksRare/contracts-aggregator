// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {OwnableTwoSteps} from "@looksrare/contracts-libs/contracts/OwnableTwoSteps.sol";
import {ReentrancyGuard} from "@looksrare/contracts-libs/contracts/ReentrancyGuard.sol";
import {LowLevelERC20Approve} from "@looksrare/contracts-libs/contracts/lowLevelCallers/LowLevelERC20Approve.sol";
import {LowLevelERC20Transfer} from "@looksrare/contracts-libs/contracts/lowLevelCallers/LowLevelERC20Transfer.sol";
import {LowLevelERC721Transfer} from "@looksrare/contracts-libs/contracts/lowLevelCallers/LowLevelERC721Transfer.sol";
import {LowLevelERC1155Transfer} from "@looksrare/contracts-libs/contracts/lowLevelCallers/LowLevelERC1155Transfer.sol";
import {IERC20} from "@looksrare/contracts-libs/contracts/interfaces/generic/IERC20.sol";
import {TokenReceiver} from "./TokenReceiver.sol";
import {ILooksRareAggregator} from "./interfaces/ILooksRareAggregator.sol";
import {ISignatureTransfer} from "./interfaces/ISignatureTransfer.sol";

/**
 * @title LooksRareAggregator
 * @notice This contract allows NFT sweepers to buy NFTs from
 *         different marketplaces by passing high-level structs
 *         + low-level bytes as calldata.
 * @author LooksRare protocol team (👀,💎)
 */
contract LooksRareAggregator is
    ILooksRareAggregator,
    TokenReceiver,
    ReentrancyGuard,
    LowLevelERC20Approve,
    LowLevelERC20Transfer,
    LowLevelERC721Transfer,
    LowLevelERC1155Transfer,
    OwnableTwoSteps
{
    ISignatureTransfer private constant PERMIT2 = ISignatureTransfer(0x000000000022D473030F116dDEE9F6B43aC78BA3);
    mapping(address => mapping(bytes4 => uint256)) private _proxyFunctionSelectors;

    /**
     * @inheritdoc ILooksRareAggregator
     */
    function execute(
        ISignatureTransfer.PermitBatchTransferFrom calldata permit,
        ISignatureTransfer.SignatureTransferDetails[] calldata transferDetails,
        bytes calldata permitSignature,
        TradeData[] calldata tradeData,
        address recipient,
        bool isAtomic
    ) external payable nonReentrant {
        if (recipient == address(0)) revert ZeroAddress();
        uint256 tradeDataLength = tradeData.length;
        if (tradeDataLength == 0) revert InvalidOrderLength();

        if (permit.permitted.length > 0) {
            PERMIT2.permitTransferFrom(permit, transferDetails, msg.sender, permitSignature);
        }

        for (uint256 i; i < tradeDataLength; ) {
            TradeData calldata singleTradeData = tradeData[i];
            address proxy = singleTradeData.proxy;
            if (_proxyFunctionSelectors[proxy][singleTradeData.selector] != 1) revert InvalidFunction();

            (bool success, bytes memory returnData) = proxy.delegatecall(
                abi.encodeWithSelector(
                    singleTradeData.selector,
                    singleTradeData.orders,
                    singleTradeData.ordersExtraData,
                    singleTradeData.extraData,
                    recipient,
                    isAtomic
                )
            );

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

        if (permit.permitted.length != 0) {
            _returnERC20TokensIfAny(permit.permitted);
        }

        bool status = true;
        assembly {
            if gt(selfbalance(), 1) {
                status := call(gas(), caller(), sub(selfbalance(), 1), 0, 0, 0, 0)
            }
        }
        if (!status) revert ETHTransferFail();

        emit Sweep(msg.sender);
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
     * @return isSupported Whether the marketplace proxy's function can be called from the aggregator
     */
    function supportsProxyFunction(address proxy, bytes4 selector) external view returns (bool isSupported) {
        isSupported = _proxyFunctionSelectors[proxy][selector] == 1;
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

    function _returnERC20TokensIfAny(ISignatureTransfer.TokenPermissions[] calldata tokenTransfers) private {
        uint256 tokenTransfersLength = tokenTransfers.length;
        for (uint256 i; i < tokenTransfersLength; ) {
            uint256 balance = IERC20(tokenTransfers[i].token).balanceOf(address(this));
            if (balance != 0) {
                _executeERC20DirectTransfer(tokenTransfers[i].token, msg.sender, balance);
            }

            unchecked {
                ++i;
            }
        }
    }
}
