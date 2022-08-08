// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "../interfaces/ILooksRareV1.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import "hardhat/console.sol";

contract LooksRareV1Proxy {
    ILooksRareV1 constant MARKETPLACE = ILooksRareV1(0x59728544B08AB483533076417FbBB2fD0B17CE3a);
    bytes4 constant INTERFACE_ID_ERC721 = 0x80ac58cd;
    bytes4 constant INTERFACE_ID_ERC1155 = 0xd9b67a26;

    error InvalidOrderLength();
    error UnrecognizedTokenInterface();
    error ZeroAddress();

    function buyWithETH(
        ILooksRareV1.TakerOrder[] calldata takerBids,
        ILooksRareV1.MakerOrder[] calldata makerAsks,
        address recipient
    ) external payable {
        uint256 takerBidsLength = takerBids.length;
        if (takerBidsLength == 0 || takerBidsLength != makerAsks.length) revert InvalidOrderLength();
        if (recipient == address(0)) revert ZeroAddress();

        for (uint256 i; i < takerBidsLength; ) {
            _matchSingleOrder(takerBids[i], makerAsks[i], recipient);
            unchecked {
                ++i;
            }
        }
    }

    function _matchSingleOrder(
        ILooksRareV1.TakerOrder calldata takerBid,
        ILooksRareV1.MakerOrder calldata makerAsk,
        address recipient
    ) private {
        try MARKETPLACE.matchAskWithTakerBidUsingETHAndWETH{value: makerAsk.price}(takerBid, makerAsk) {
            // TODO: handle CryptoPunks/Mooncats
            if (IERC165(makerAsk.collection).supportsInterface(INTERFACE_ID_ERC721)) {
                IERC721(makerAsk.collection).transferFrom(address(this), recipient, makerAsk.tokenId);
            } else if (IERC165(makerAsk.collection).supportsInterface(INTERFACE_ID_ERC1155)) {
                IERC1155(makerAsk.collection).safeTransferFrom(
                    address(this),
                    recipient,
                    makerAsk.tokenId,
                    makerAsk.amount,
                    "0x"
                );
            } else {
                revert UnrecognizedTokenInterface();
            }
        } catch (bytes memory returnData) {
            if (returnData.length > 0) {
                assembly {
                    let returnDataSize := mload(returnData)
                    revert(add(32, returnData), returnDataSize)
                }
            } else {}
        }
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}
