import { execSync } from "child_process";

const config = [
  {
    fileName: "aggregator-sudoswap.ts",
    forkedBlock: 15315621,
  },
  {
    fileName: "aggregator-cryptopunks.ts",
    forkedBlock: 15358065,
  },
  {
    fileName: "aggregator-x2y2.ts",
    forkedBlock: 15346990,
  },
  {
    fileName: "aggregator-looksrare.ts",
    forkedBlock: 15282897,
  },
  {
    fileName: "aggregator-seaport-erc721-atomic.ts",
    forkedBlock: 15300884,
  },
  {
    fileName: "aggregator-seaport-erc721-non-atomic.ts",
    forkedBlock: 15300884,
  },
  {
    fileName: "aggregator-seaport-erc721-only-usdc-orders-atomic.ts",
    forkedBlock: 15491323,
  },
  {
    fileName: "aggregator-seaport-erc721-only-usdc-orders-non-atomic.ts",
    forkedBlock: 15491323,
  },
  {
    fileName: "aggregator-seaport-erc1155-atomic.ts",
    forkedBlock: 15320038,
  },
  {
    fileName: "aggregator-seaport-erc1155-non-atomic.ts",
    forkedBlock: 15320038,
  },
  {
    fileName: "aggregator-seaport-multiple-collection-types.ts",
    forkedBlock: 15323472,
  },
  {
    fileName: "aggregator-seaport-multiple-currencies-atomic.ts",
    forkedBlock: 15447813,
  },
  {
    fileName: "aggregator-seaport-multiple-currencies-non-atomic.ts",
    forkedBlock: 15447813,
  },
  {
    fileName: "aggregator-seaport-erc721-multiple-currencies-random-order-fees-atomic.ts",
    forkedBlock: 15491323,
  },
  {
    fileName: "aggregator-seaport-erc721-multiple-currencies-random-order-fees-non-atomic.ts",
    forkedBlock: 15491323,
  },
  {
    fileName: "aggregator-conflicted-orders.ts",
    forkedBlock: 15327113,
  },
  {
    fileName: "aggregator-multiple-markets.ts",
    forkedBlock: 15326566,
  },
];

// eslint-disable-next-line @typescript-eslint/no-explicit-any
function runHardhatTests(config: string | any[]): void {
  for (let i = 0; i < config.length; i++) {
    execSync(
      "FORKED_BLOCK_NUMBER=" +
        String(config[i].forkedBlock) +
        " npx hardhat test test/typescript/" +
        String(config[i].fileName),
      {
        stdio: "inherit",
      }
    );
  }
}

runHardhatTests(config);
