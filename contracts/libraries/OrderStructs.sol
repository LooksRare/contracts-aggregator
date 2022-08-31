// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import {CollectionType} from "./OrderEnums.sol";

struct BasicOrder {
  address signer; // The order's maker
  address collection; // The address of the ERC-721/ERC-1155 token to be purchased
  CollectionType collectionType; // 0 for ERC-721, 1 for ERC-1155
  uint256[] tokenIds; // The IDs of the tokens to be purchased
  uint256[] amounts; // Always 1 when ERC-721, can be > 1 if ERC-1155
  uint256 price; // The *taker bid* price to pay for the order
  address currency; // The order's currency, address(0) for ETH
  uint256 startTime; // The timestamp when the order starts becoming valid
  uint256 endTime; // The timestamp when the order stops becoming valid
  bytes signature; // split to v,r,s for LooksRare
}

struct TokenTransfer {
    uint256 amount;
    address currency;
}