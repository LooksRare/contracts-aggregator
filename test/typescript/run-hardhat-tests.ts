import { execSync } from "child_process";

const config = [
  "aggregator-sudoswap.ts",
  "aggregator-cryptopunks.ts",
  "aggregator-x2y2.ts",
  "aggregator-looksrare.ts",
  "aggregator-seaport-erc721-atomic.ts",
  "aggregator-seaport-erc721-non-atomic.ts",
  "aggregator-seaport-erc721-only-usdc-orders-atomic.ts",
  "aggregator-seaport-erc721-only-usdc-orders-non-atomic.ts",
  "aggregator-seaport-erc1155-atomic.ts",
  "aggregator-seaport-erc1155-non-atomic.ts",
  "aggregator-seaport-multiple-collection-types.ts",
  "aggregator-seaport-multiple-currencies-atomic.ts",
  "aggregator-seaport-multiple-currencies-non-atomic.ts",
  "aggregator-seaport-erc721-multiple-currencies-random-order-fees-atomic.ts",
  "aggregator-seaport-erc721-multiple-currencies-random-order-fees-non-atomic.ts",
  "aggregator-conflicted-orders.ts",
  "aggregator-multiple-markets.ts",
];

// eslint-disable-next-line @typescript-eslint/no-explicit-any
function runHardhatTests(config: string | any[]): void {
  for (let i = 0; i < config.length; i++) {
    execSync("npx hardhat test test/typescript/" + String(config[i]), {
      stdio: "inherit",
    });
  }
}

runHardhatTests(config);
