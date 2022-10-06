// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {CollectionType} from "./libraries/OrderEnums.sol";
import {IERC721} from "@looksrare/contracts-libs/contracts/interfaces/generic/IERC721.sol";
import {IERC1155} from "@looksrare/contracts-libs/contracts/interfaces/generic/IERC1155.sol";

abstract contract TokenTransferrer {
    function _transferTokenToRecipient(
        CollectionType collectionType,
        address recipient,
        address collection,
        uint256 tokenId,
        uint256 amount
    ) internal {
        if (collectionType == CollectionType.ERC721) {
            IERC721(collection).transferFrom(address(this), recipient, tokenId);
        } else if (collectionType == CollectionType.ERC1155) {
            IERC1155(collection).safeTransferFrom(address(this), recipient, tokenId, amount, "");
        }
    }
}
