export const BAYC = "0xbc4ca0eda7647a8ab7c2061c2e118a18a936f13d";
export const CITY_DAO = "0x7EeF591A6CC0403b9652E98E88476fe1bF31dDeb";
export const MOODIE = "0xda4c9ffb9a96ef44865114be4af25004f0ee385d";
export const FULFILLER_CONDUIT_KEY = "0x0000000000000000000000000000000000000000000000000000000000000000";
export const LOOKSRARE_STRATEGY_FIXED_PRICE = "0x56244Bb70CbD3EA9Dc8007399F61dFC065190031";
export const OPENSEA_FEES = "0x8De9C5A032463C561423387a9648c5C7BCC5BC90";
export const SEAPORT = "0x00000000006c3852cbef3e08e8df289169ede581";
export const WETH = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2";
export const ZONE_HASH = "0x0000000000000000000000000000000000000000000000000000000000000000";

export const SEAPORT_EXTRA_DATA_SCHEMA = `
  tuple(
    tuple(uint256 orderIndex, uint256 itemIndex)[][] offerFulfillments,
    tuple(uint256 orderIndex, uint256 itemIndex)[][] considerationFulfillments
  )
`;

export const SEAPORT_ORDER_EXTRA_DATA_SCHEMA = `
  tuple(
    uint8 orderType,
    address zone,
    bytes32 zoneHash,
    uint256 salt,
    bytes32 conduitKey,
    tuple(address recipient, uint256 amount)[] recipients
  ) orderExtraData
`;

export const LOOKSRARE_EXTRA_DATA_SCHEMA = ["address", "uint256", "uint256"];

export const SEAPORT_OFFER_FULFILLMENT_ONE_ITEM = [[{ orderIndex: 0, itemIndex: 0 }]];

export const SEAPORT_OFFER_FULFILLMENT_TWO_ITEMS = [
  [{ orderIndex: 0, itemIndex: 0 }],
  [{ orderIndex: 1, itemIndex: 0 }],
];

export const SEAPORT_CONSIDERATION_FULFILLMENTS_ONE_ORDER = [
  // seller one
  [{ orderIndex: 0, itemIndex: 0 }],
  // OpenSea: Fees
  [{ orderIndex: 0, itemIndex: 1 }],
  // royalty
  [{ orderIndex: 0, itemIndex: 2 }],
];

export const SEAPORT_CONSIDERATION_FULFILLMENTS_TWO_ORDERS_SAME_COLLECTION = [
  // seller one
  [{ orderIndex: 0, itemIndex: 0 }],
  // seller two
  [{ orderIndex: 1, itemIndex: 0 }],
  // OpenSea: Fees
  [
    { orderIndex: 0, itemIndex: 1 },
    { orderIndex: 1, itemIndex: 1 },
  ],
  // royalty
  [
    { orderIndex: 0, itemIndex: 2 },
    { orderIndex: 1, itemIndex: 2 },
  ],
];

export const SEAPORT_CONSIDERATION_FULFILLMENTS_TWO_ORDERS_DIFFERENT_COLLECTIONS = [
  // seller one
  [{ orderIndex: 0, itemIndex: 0 }],
  // seller two
  [{ orderIndex: 1, itemIndex: 0 }],
  // OpenSea: Fees
  [
    { orderIndex: 0, itemIndex: 1 },
    { orderIndex: 1, itemIndex: 1 },
  ],
  // royalty one
  [{ orderIndex: 0, itemIndex: 2 }],
  // royalty two
  [{ orderIndex: 1, itemIndex: 2 }],
];
