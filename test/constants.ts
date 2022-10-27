export const BAYC = "0xbc4ca0eda7647a8ab7c2061c2e118a18a936f13d";
export const MOODIE = "0xda4c9ffb9a96ef44865114be4af25004f0ee385d";
export const PARALLEL = "0x76BE3b62873462d2142405439777e971754E8E77";
export const SUDOSWAP = "0x2B2e8cDA09bBA9660dCA5cB6233787738Ad68329";
export const X2Y2 = "0x74312363e45DCaBA76c59ec49a7Aa8A65a67EeD3";

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

export const SWEEP_TOPIC = "0x807273efecfbeb7ae7d3a2189d1ed5a7db80074eed86e7d80b10bb925cd1db73";
