# Aggregator

This is an aggregator that allows NFT sweepers to buy NFTs from multiple sources in a single transaction (LooksRare, Seaport, X2Y2, Sudoswap, etc).

## About this repo

### How to interact with the contracts

LooksRareAggregator is the entrypoint for a batch transaction. Clients should submit a list of trade data for different marketplaces to the aggregator. However, it is only recommended when the trade data belongs to different marketplaces. It is cheaper to interact with the proxy (LooksRare, X2Y2, CryptoPunks) or even the marketplace directly (Seaport, Sudoswap) when the sweeping is only targeting one marketplace.
Generally speaking, if the marketplace supports buying multiple NFTs at once, the client should avoid the proxy. Using a proxy is only beneficial if the marketplace does not support submitting multiple orders at once.

### Structure

It is a hybrid [Hardhat](https://hardhat.org/) repo that also requires [Foundry](https://book.getfoundry.sh/index.html) to run Solidity tests powered by the [ds-test library](https://github.com/dapphub/ds-test/).

> To install Foundry, please follow the instructions [here](https://book.getfoundry.sh/getting-started/installation.html).

### Run tests

- TypeScript tests are included in the `typescript` folder in the `test` folder at the root of the repo.
- Solidity tests are included in the `foundry` folder in the `test` folder at the root of the repo.

### Example of Foundry/Forge commands

```shell
forge build
forge test
forge test -vv
forge tree
```

### Example of Hardhat commands

```shell
npx hardhat accounts
npx hardhat compile
npx hardhat clean
npx hardhat test
npx hardhat node
npx hardhat help
REPORT_GAS=true npx hardhat test
npx hardhat coverage
npx hardhat run scripts/deploy.ts
TS_NODE_FILES=true npx ts-node scripts/deploy.ts
npx eslint '**/*.{js,ts}'
npx eslint '**/*.{js,ts}' --fix
npx prettier '**/*.{json,sol,md}' --check
npx prettier '**/*.{json,sol,md}' --write
npx solhint 'contracts/**/*.sol'
npx solhint 'contracts/**/*.sol' --fix
```

### Running tests for each marketplace

Each test file requires a different block number as I retrieve the listings in different days.
To keep it easy for now, just provide the block number so that the listing is still valid.

There is probably a better way to do this and we can re-visit later.

```shell
FORKED_BLOCK_NUMBER=15358065 npx hardhat test test/typescript/aggregator-cryptopunks.ts
FORKED_BLOCK_NUMBER=15346990 npx hardhat test test/typescript/aggregator-x2y2.ts
FORKED_BLOCK_NUMBER=15282897 npx hardhat test test/typescript/aggregator-looksrare.ts
FORKED_BLOCK_NUMBER=15327113 npx hardhat test test/typescript/aggregator-conflicted-orders.ts
FORKED_BLOCK_NUMBER=15326566 npx hardhat test test/typescript/aggregator-multiple-markets.ts
FORKED_BLOCK_NUMBER=15323472 npx hardhat test test/typescript/aggregator-seaport-multiple-collection-types.ts
FORKED_BLOCK_NUMBER=15300884 npx hardhat test test/typescript/aggregator-seaport-erc-721-atomic.ts
FORKED_BLOCK_NUMBER=15300884 npx hardhat test test/typescript/aggregator-seaport-erc-721-non-atomic.ts
FORKED_BLOCK_NUMBER=15320038 npx hardhat test test/typescript/aggregator-seaport-erc-1155-atomic.ts
FORKED_BLOCK_NUMBER=15320038 npx hardhat test test/typescript/aggregator-seaport-erc-1155-non-atomic.ts
FORKED_BLOCK_NUMBER=15300884 npx hardhat test test/typescript/direct-seaport-single.ts
FORKED_BLOCK_NUMBER=15302889 npx hardhat test test/typescript/v0-aggregator-seaport-looksrare-combined.ts
FORKED_BLOCK_NUMBER=15300884 npx hardhat test test/typescript/v0-aggregator-seaport-single.ts
FORKED_BLOCK_NUMBER=15282897 npx hardhat test test/typescript/v0-aggregator-looksrare-single.ts
```
