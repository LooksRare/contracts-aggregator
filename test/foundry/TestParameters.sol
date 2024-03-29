// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract TestParameters {
    address internal constant BAYC = 0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D;
    address internal constant CRYPTOPUNKS = 0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB;
    address internal constant GEMSWAP = 0x83C8F28c26bF6aaca652Df1DbBE0e1b56F8baBa2;
    address internal constant LOOKSRARE_V1 = 0x59728544B08AB483533076417FbBB2fD0B17CE3a;
    address internal constant LOOKSRARE_V2_GOERLI = 0x35C2215F2FFe8917B06454eEEaba189877F200cf;
    address internal constant LOOKSRARE_V2_TRANSFER_MANAGER_GOERLI = 0xC20E0CeAD98abBBEb626B77efb8Dc1E5D781f90c;
    address internal constant LOOKSRARE_STRATEGY_FIXED_PRICE = 0x56244Bb70CbD3EA9Dc8007399F61dFC065190031;
    address internal constant LOOKSRARE_STRATEGY_FIXED_PRICE_V1B = 0x579af6FD30BF83a5Ac0D636bc619f98DBdeb930c;
    address internal constant MOODIE = 0x0F23939EE95350F26D9C1B818Ee0Cc1C8Fd2b99D;
    address internal constant SUDOSWAP = 0x2B2e8cDA09bBA9660dCA5cB6233787738Ad68329;
    address internal constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address internal constant WETH_GOERLI = 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6;
    address internal constant X2Y2 = 0x74312363e45DCaBA76c59ec49a7Aa8A65a67EeD3;

    // keccak256(_buyer)
    address internal constant _buyer =
        address(uint160(uint256(0xb8508abe31ca4035b2557f0d38dee936aa3d8e6370524a7cba38c96a896d9d9f)));
    // keccak256(_fakeAggregator)
    address internal constant _fakeAggregator =
        address(uint160(uint256(0x7067d68cd5bbbdae43f8985009b4baf784f2fe81b86faf14afa04c6f162f34e9)));
    // keccak256(_notOwner)
    address internal constant _notOwner =
        address(uint160(uint256(0x6186fde1900f65852320d9cd9c1d976dc5540ba7e6b88ae8e8ba11bc79d831ec)));
    // keccak256(_luckyUser)
    address internal constant _luckyUser =
        address(uint160(uint256(0x1f0f3d7d9f70e9b50d1e198cedb3af2fbaa2c2617539c746de35fffce19946df)));

    uint256 internal constant luckyNumber = 6.9420 ether;

    uint256 internal constant INITIAL_ETH_BALANCE = 400 ether;
    uint256 internal constant INITIAL_USDC_BALANCE = 500_000e6;

    event FunctionAdded(address proxy, bytes4 selector);
    event FunctionRemoved(address proxy, bytes4 selector);
    event Sweep(address sweeper);
}
