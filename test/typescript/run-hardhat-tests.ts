import { execSync } from "child_process";

const config = [
  {
    fileName: "aggregator-sudoswap.ts",
  },
  {
    fileName: "aggregator-cryptopunks.ts",
  },
  {
    fileName: "aggregator-x2y2.ts",
  },
  {
    fileName: "aggregator-looksrare.ts",
  },
  {
    fileName: "aggregator-seaport-erc721-atomic.ts",
  },
  {
    fileName: "aggregator-seaport-erc721-non-atomic.ts",
  },
  {
    fileName: "aggregator-seaport-erc721-only-usdc-orders-atomic.ts",
  },
  {
    fileName: "aggregator-seaport-erc721-only-usdc-orders-non-atomic.ts",
  },
  {
    fileName: "aggregator-seaport-erc1155-atomic.ts",
  },
  {
    fileName: "aggregator-seaport-erc1155-non-atomic.ts",
  },
  {
    fileName: "aggregator-seaport-multiple-collection-types.ts",
  },
  {
    fileName: "aggregator-seaport-multiple-currencies-atomic.ts",
  },
  {
    fileName: "aggregator-seaport-multiple-currencies-non-atomic.ts",
  },
  {
    fileName: "aggregator-seaport-erc721-multiple-currencies-random-order-fees-atomic.ts",
  },
  {
    fileName: "aggregator-seaport-erc721-multiple-currencies-random-order-fees-non-atomic.ts",
  },
  {
    fileName: "aggregator-conflicted-orders.ts",
  },
  {
    fileName: "aggregator-multiple-markets.ts",
  },
];

// eslint-disable-next-line @typescript-eslint/no-explicit-any
function runHardhatTests(config: string | any[]): void {
  for (let i = 0; i < config.length; i++) {
    execSync("npx hardhat test test/typescript/" + String(config[i].fileName), {
      stdio: "inherit",
    });
  }
}

runHardhatTests(config);
