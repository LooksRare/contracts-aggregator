# @looksrare/contracts-aggregator

[![Tests](https://github.com/LooksRare/contracts-aggregator/actions/workflows/tests.yaml/badge.svg)](https://github.com/LooksRare/contracts-aggregator/actions/workflows/tests.yaml)

This is an aggregator that allows NFT sweepers to buy NFTs from multiple sources in a single transaction (LooksRare, Seaport, X2Y2, Sudoswap, etc).

## About this repo

### Structure

It is a hybrid [Hardhat](https://hardhat.org/) repo that also requires [Foundry](https://book.getfoundry.sh/index.html) to run Solidity tests powered by the [ds-test library](https://github.com/dapphub/ds-test/).

> To install Foundry, please follow the instructions [here](https://book.getfoundry.sh/getting-started/installation.html).

### Architecture

- `LooksRareAggregator` is the entrypoint for a batch transaction. Clients should submit a list of trade data for different marketplaces to the aggregator.

- The `proxies` folder contains the proxy contracts for each marketplace. All proxies should be named in the format of `${Marketplace}Proxy` and inherit from the interface `IProxy`.

- The `libraries` folder contains various structs and enums required. Objects that are specific to a marketplace should be put inside the `${marketplace}` child folder.

- In order to create more realistic tests, real listings from real collections are fetched from each marketplace. For listing objects that are full API responses, they are put inside the `test/typescript/fixtures/${marketplace}` folder. For marketplaces like CryptoPunks and Sudoswap, it is ok to just put the data in the tests.

- Any contract that's prefixed with V0 will not go live. They come from our first iteration. We are only keeping them for now for reference.

### Run tests

- TypeScript tests are included in the `typescript` folder in the `test` folder at the root of the repo.
- Solidity tests are included in the `foundry` folder in the `test` folder at the root of the repo.

### Running tests for each marketplace

Each test file requires a different block number as the listings were retrieved in different days and they have an expiration timestamp.

```shell
FORKED_BLOCK_NUMBER=15315621 npx hardhat test test/typescript/aggregator-sudoswap.ts
FORKED_BLOCK_NUMBER=15358065 npx hardhat test test/typescript/aggregator-cryptopunks.ts
FORKED_BLOCK_NUMBER=15346990 npx hardhat test test/typescript/aggregator-x2y2.ts
FORKED_BLOCK_NUMBER=15282897 npx hardhat test test/typescript/aggregator-looksrare.ts
FORKED_BLOCK_NUMBER=15327113 npx hardhat test test/typescript/aggregator-conflicted-orders.ts
FORKED_BLOCK_NUMBER=15326566 npx hardhat test test/typescript/aggregator-multiple-markets.ts
FORKED_BLOCK_NUMBER=15323472 npx hardhat test test/typescript/aggregator-seaport-multiple-collection-types.ts
FORKED_BLOCK_NUMBER=15447813 npx hardhat test test/typescript/aggregator-seaport-multiple-currencies-atomic.ts
FORKED_BLOCK_NUMBER=15447813 npx hardhat test test/typescript/aggregator-seaport-multiple-currencies-non-atomic.ts
FORKED_BLOCK_NUMBER=15300884 npx hardhat test test/typescript/aggregator-seaport-erc-721-atomic.ts
FORKED_BLOCK_NUMBER=15300884 npx hardhat test test/typescript/aggregator-seaport-erc-721-non-atomic.ts
FORKED_BLOCK_NUMBER=15320038 npx hardhat test test/typescript/aggregator-seaport-erc-1155-atomic.ts
FORKED_BLOCK_NUMBER=15320038 npx hardhat test test/typescript/aggregator-seaport-erc-1155-non-atomic.ts
FORKED_BLOCK_NUMBER=15491323 npx hardhat test test/typescript/aggregator-seaport-erc-721-only-usdc-orders-atomic.ts
FORKED_BLOCK_NUMBER=15491323 npx hardhat test test/typescript/aggregator-seaport-erc-721-only-usdc-orders-non-atomic.ts
FORKED_BLOCK_NUMBER=15491323 npx hardhat test test/typescript/aggregator-seaport-erc-721-multiple-currencies-random-order-fees-atomic.ts
FORKED_BLOCK_NUMBER=15491323 npx hardhat test test/typescript/aggregator-seaport-erc-721-multiple-currencies-random-order-fees-non-atomic.ts
FORKED_BLOCK_NUMBER=15300884 npx hardhat test test/typescript/direct-seaport-single.ts
FORKED_BLOCK_NUMBER=15302889 npx hardhat test test/typescript/v0-aggregator-seaport-looksrare-combined.ts
FORKED_BLOCK_NUMBER=15300884 npx hardhat test test/typescript/v0-aggregator-seaport-single.ts
FORKED_BLOCK_NUMBER=15300884 npx hardhat test test/typescript/v0-aggregator-seaport-multiple.ts
FORKED_BLOCK_NUMBER=15282897 npx hardhat test test/typescript/v0-aggregator-looksrare-single.ts
```

### Gas benchmark

```
forge test --match-contract GemSwapBenchmarkTest
forge test --match-contract LooksRareProxyBenchmarkTest
forge test --match-contract SeaportProxyBenchmarkTest
```

### Static analysis

```
pip3 install slither-analyzer
pip3 install solc-select
solc-select install 0.8.17
solc-select use 0.8.17
slither --solc solc-0.8.17 .
```
