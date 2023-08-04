# @looksrare/contracts-aggregator

[![Tests](https://github.com/LooksRare/contracts-aggregator/actions/workflows/tests.yaml/badge.svg)](https://github.com/LooksRare/contracts-aggregator/actions/workflows/tests.yaml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![SDK](https://img.shields.io/badge/SDK-library-red)](https://github.com/LooksRare/sdk-aggregator)

This repo contains an aggregator smart contract system that allows NFT sweepers to buy NFTs from multiple sources in a single transaction (LooksRare, Seaport, X2Y2, Sudoswap, etc).

## About this repo

### Structure

It is a hybrid [Hardhat](https://hardhat.org/) repo that also requires [Foundry](https://book.getfoundry.sh/index.html) to run Solidity tests powered by the [ds-test library](https://github.com/dapphub/ds-test/).

> To install Foundry, please follow the instructions [here](https://book.getfoundry.sh/getting-started/installation.html).

### Deployments

| Network  | LooksRareAggregator                                                                                                           | ERC20EnabledLooksRareAggregator                                                                                               | LooksRareProxy                                                                                                               | LooksRareV2Proxy                                                                                                              | SeaportProxy                                                                                                                  |
| -------- | ----------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------- |
| Ethereum | [0x00000000005228B791a99a61f36A130d50600106](https://etherscan.io/address/0x00000000005228B791a99a61f36A130d50600106)         | [0x0000000000a35231D7706BD1eE827d43245655aB](https://etherscan.io/address/0x0000000000a35231D7706BD1eE827d43245655aB)         | [0x0000000000DA151039Ed034d1C5BACb47C284Ed1](https://etherscan.io/address/0x0000000000DA151039Ed034d1C5BACb47C284Ed1)        | [0x000000000074f2e99d7602fCA3cf0ffdCa906495](https://etherscan.io/address/0x000000000074f2e99d7602fCA3cf0ffdCa906495)         | [0x000000000055d65008F1dFf7167f24E70DB431F6](https://etherscan.io/address/0x000000000055d65008F1dFf7167f24E70DB431F6)         |
| Goerli   | [0x00000000005228B791a99a61f36A130d50600106](https://goerli.etherscan.io/address/0x00000000005228B791a99a61f36A130d50600106)  | [0x0000000000a35231D7706BD1eE827d43245655aB](https://goerli.etherscan.io/address/0x0000000000a35231D7706BD1eE827d43245655aB)  | [0xd23F81a978E8F88F1c289C69D87fFC7D0b56b3c0](https://goerli.etherscan.io/address/0xd23F81a978E8F88F1c289C69D87fFC7D0b56b3c0) | [0x5AAf7A47A96f4695b4c5F4d4706C04ae606FA59f](https://goerli.etherscan.io/address/0x5AAf7A47A96f4695b4c5F4d4706C04ae606FA59f)  | [0x000000000055d65008F1dFf7167f24E70DB431F6](https://goerli.etherscan.io/address/0x000000000055d65008F1dFf7167f24E70DB431F6)  |
| Sepolia  | [0x00000000005228B791a99a61f36A130d50600106](https://sepolia.etherscan.io/address/0x00000000005228B791a99a61f36A130d50600106) | [0x0000000000a35231D7706BD1eE827d43245655aB](https://sepolia.etherscan.io/address/0x0000000000a35231D7706BD1eE827d43245655aB) |                                                                                                                              | [0xbe1A28000cfE2009051ac6F5b865BC03a04be875](https://sepolia.etherscan.io/address/0xbe1A28000cfE2009051ac6F5b865BC03a04be875) | [0x000000000055d65008F1dFf7167f24E70DB431F6](https://sepolia.etherscan.io/address/0x000000000055d65008F1dFf7167f24E70DB431F6) |

### Architecture

![ETH order](https://user-images.githubusercontent.com/98446738/200664905-b7bd4126-d6bd-4d35-aad0-7b99f1ef84fa.jpeg)
![ERC20 order](https://user-images.githubusercontent.com/98446738/200664939-f4b21fb3-e045-4b65-95b6-bb5db053ea47.jpeg)

- `LooksRareAggregator` is the entrypoint for a batch transaction with orders paid only in ETH. Clients should submit a list of trade data for different marketplaces to the aggregator.

- `ERC20EnabledLooksRareAggregator` is the entrypoint for a batch transaction with orders paid in ERC20 tokens. Clients should submit a list of trade data for different marketplaces to the aggregator. The purpose of this aggregator is to prevent malicious proxies from stealing client funds since ERC20 approvals are not given to `LooksRareAggregator`.

- The `proxies` folder contains the proxy contracts for each marketplace. All proxies should be named in the format of `${Marketplace}Proxy` and inherit from the interface `IProxy`.

- The `libraries` folder contains various structs and enums required. Objects that are specific to a marketplace should be put inside the `${marketplace}` child folder.

- In order to create more realistic tests, real listings from real collections are fetched from each marketplace.

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

### Coverage

```
forge coverage --report lcov
LCOV_EXCLUDE=("test/*" "contracts/prototype/*")
echo $LCOV_EXCLUDE | xargs lcov --output-file lcov-filtered.info --remove lcov.info
genhtml lcov-filtered.info --output-directory out
open out/index.html
```
