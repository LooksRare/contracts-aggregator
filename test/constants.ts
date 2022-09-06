export const BAYC = "0xbc4ca0eda7647a8ab7c2061c2e118a18a936f13d";
export const CITY_DAO = "0x7EeF591A6CC0403b9652E98E88476fe1bF31dDeb";
export const CRYPTOPUNKS = "0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB";
export const MOODIE = "0xda4c9ffb9a96ef44865114be4af25004f0ee385d";
export const PARALLEL = "0x76BE3b62873462d2142405439777e971754E8E77";
export const FULFILLER_CONDUIT_KEY = "0x0000000000000000000000000000000000000000000000000000000000000000";
export const LOOKSRARE_V1 = "0x59728544B08AB483533076417FbBB2fD0B17CE3a";
export const LOOKSRARE_STRATEGY_FIXED_PRICE = "0x56244Bb70CbD3EA9Dc8007399F61dFC065190031";
export const OPENSEA_FEES = "0x8De9C5A032463C561423387a9648c5C7BCC5BC90";
export const SEAPORT = "0x00000000006c3852cbef3e08e8df289169ede581";
export const SUDOSWAP = "0x2B2e8cDA09bBA9660dCA5cB6233787738Ad68329";
export const USDC = "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48";
export const USDC_WHALE = "0x2faf487a4414fe77e2327f0bf4ae2a264a776ad2"; // FTX
export const WETH = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2";
export const X2Y2 = "0x74312363e45DCaBA76c59ec49a7Aa8A65a67EeD3";
export const ZONE_HASH = "0x0000000000000000000000000000000000000000000000000000000000000000";

export const SEAPORT_EXTRA_DATA_SCHEMA = `
  tuple(
    tuple(uint256 orderIndex, uint256 itemIndex)[][] offerFulfillments,
    tuple(uint256 orderIndex, uint256 itemIndex)[][] considerationFulfillments
  )
`;

export const SEAPORT_ORDER_EXTRA_DATA_SCHEMA = `
  tuple(
    uint120 numerator,
    uint120 denominator,
    uint8 orderType,
    address zone,
    bytes32 zoneHash,
    uint256 salt,
    bytes32 conduitKey,
    tuple(uint256 amount, address recipient)[] recipients
  ) orderExtraData
`;

export const X2Y2_ORDER_EXTRA_DATA_SCHEMA = `
  tuple(
    uint256 salt,
    bytes itemData,
    uint256 inputSalt,
    uint256 inputDeadline,
    address executionDelegate,
    uint8 inputV,
    bytes32 inputR,
    bytes32 inputS,
    tuple(uint256 percentage, address to)[] fees
  ) orderExtraData
`;

export const LOOKSRARE_EXTRA_DATA_SCHEMA = ["uint256", "uint256", "uint256", "address"];

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

export const SEAPORT_CONSIDERATION_FULFILLMENTS_TWO_ORDERS_DIFFERENT_CURRENCIES = [
  // seller one
  [{ orderIndex: 0, itemIndex: 0 }],
  // seller two
  [{ orderIndex: 1, itemIndex: 0 }],
  // OpenSea: Fees
  [{ orderIndex: 0, itemIndex: 1 }],
  [{ orderIndex: 1, itemIndex: 1 }],
  // royalty
  [{ orderIndex: 0, itemIndex: 2 }],
  [{ orderIndex: 1, itemIndex: 2 }],
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

export const SWEEP_TOPIC = "0x3da7689974f13093359934c7f011f3c8cbe727f25892e588f8eef693942efa4c";
