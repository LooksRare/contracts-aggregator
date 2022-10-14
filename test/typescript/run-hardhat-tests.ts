import { execSync } from "child_process";

// TODO
const config = [
  {
    fileName: "aggregator-sudoswap.ts",
    forkedBlock: 15315621,
  },
  {
    fileName: "aggregator-cryptopunks.ts",
    forkedBlock: 15358065,
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
