// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {CollectionType} from "./OrderEnums.sol";

struct BasicOrder {
    /* The order's maker */
    address signer;
    /* The address of the ERC721/ERC1155 token to be purchased */
    address collection;
    /* 0 for ERC721, 1 for ERC1155 */
    CollectionType collectionType;
    /* The IDs of the tokens to be purchased */
    uint256[] tokenIds;
    /* Always 1 when ERC721, can be > 1 if ERC1155 */
    uint256[] amounts;
    /* The *taker bid* price to pay for the order */
    uint256 price;
    /* The order's currency, address(0) for ETH */
    address currency;
    /* The timestamp when the order starts becoming valid */
    uint256 startTime;
    /* The timestamp when the order stops becoming valid */
    uint256 endTime;
    /* split to v,r,s for LooksRare */
    bytes signature;
}

struct TokenTransfer {
    /* ERC20 transfer amount */
    uint256 amount;
    /* ERC20 transfer currency */
    address currency;
}

struct FeeData {
    /* Aggregator fee basis point */
    uint256 bp;
    /* Aggregator fee recipient */
    address recipient;
}
