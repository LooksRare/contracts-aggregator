// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import {CollectionType} from "./OrderEnums.sol";

struct BasicOrder {
  address signer; // signer for LooksRare, offerer for Seaport
  address recipient;
  address collection;
  CollectionType collectionType;
  uint256[] tokenIds;
  uint256[] amounts; // always 1 when ERC-721, can be > 1 if ERC-1155
  uint256 price;
  address currency;
  uint256 startTime;
  uint256 endTime;
  bytes signature; // split to v,r,s for LooksRare
}