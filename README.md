# @looksrare/contracts-aggregator

[![Tests](https://github.com/LooksRare/contracts-aggregator/actions/workflows/tests.yaml/badge.svg)](https://github.com/LooksRare/contracts-aggregator/actions/workflows/tests.yaml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![SDK](https://img.shields.io/badge/SDK-library-red)](https://github.com/LooksRare/sdk-aggregator)

This repo contains an aggregator smart contract system that allows NFT sweepers to buy NFTs from multiple sources in a single transaction (LooksRare, Seaport, X2Y2, Sudoswap, etc).

## About this repo

### Structure

It is a hybrid [Hardhat](https://hardhat.org/) repo that also requires [Foundry](https://book.getfoundry.sh/index.html) to run Solidity tests powered by the [ds-test library](https://github.com/dapphub/ds-test/).

> To install Foundry, please follow the instructions [here](https://book.getfoundry.sh/getting-started/installation.html).

### Architecture

- `LooksRareAggregator` is the entrypoint for a batch transaction with orders paid only in ETH. Clients should submit a list of trade data for different marketplaces to the aggregator.

- `ERC20EnabledLooksRareAggregator` is the entrypoint for a batch transaction with orders paid in ERC20 tokens. Clients should submit a list of trade data for different marketplaces to the aggregator. The purpose of this aggregator is to prevent malicious proxies from stealing client funds since ERC20 approvals are not given to `LooksRareAggregator`.

- The `proxies` folder contains the proxy contracts for each marketplace. All proxies should be named in the format of `${Marketplace}Proxy` and inherit from the interface `IProxy`.

- The `libraries` folder contains various structs and enums required. Objects that are specific to a marketplace should be put inside the `${marketplace}` child folder.

- In order to create more realistic tests, real listings from real collections are fetched from each marketplace. For listing objects that are full API responses, they are put inside the `test/typescript/fixtures/${marketplace}` folder. For marketplaces like CryptoPunks and Sudoswap, it is ok to just put the data in the tests.

- Any contract that's prefixed with V0 will not go live. They come from our first iteration. We are only keeping them for now for reference.

### Run tests

- TypeScript tests are included in the `typescript` folder in the `test` folder at the root of the repo.
- Solidity tests are included in the `foundry` folder in the `test` folder at the root of the repo.

In order to speed up build time without running into the notorious "stack too deep" issue,
use the local Foundry profile to run the tests.

`FOUNDRY_PROFILE=local forge test`

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
