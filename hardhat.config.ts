import type { HardhatUserConfig } from "hardhat/types";
import { task } from "hardhat/config";

import "@nomiclabs/hardhat-etherscan";
import "@nomiclabs/hardhat-waffle";
import "@typechain/hardhat";
import "hardhat-abi-exporter";
import "hardhat-gas-reporter";
import "solidity-coverage";
import "dotenv/config";

task("accounts", "Prints the list of accounts", async (_args, hre) => {
  const accounts = await hre.ethers.getSigners();
  accounts.forEach(async (account) => console.info(account.address));
});

const config: HardhatUserConfig = {
  defaultNetwork: "hardhat",
  networks: {
    hardhat: {
      allowUnlimitedContractSize: false,
      chainId: process.env.HARDHAT_CHAIN_ID ? Number(process.env.HARDHAT_CHAIN_ID) : 31337,
      forking: {
        // eslint-disable-next-line @typescript-eslint/no-non-null-assertion
        url: process.env.ETH_RPC_URL!,
        blockNumber: process.env.FORKED_BLOCK_NUMBER ? Number(process.env.FORKED_BLOCK_NUMBER) : undefined,
      },
      hardfork: "berlin", // Berlin is used (temporarily) to avoid issues with coverage
      mining: {
        auto: true,
        interval: 50000,
      },
      gasPrice: "auto",
    },
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_KEY,
  },
  solidity: {
    compilers: [
      {
        version: "0.8.14",
        settings: { optimizer: { enabled: true, runs: 888888 } },
      },
      {
        version: "0.4.18",
        settings: { optimizer: { enabled: true, runs: 999 } },
      },
    ],
  },
  paths: {
    sources: "./contracts/",
    tests: "./test",
    cache: "./cache",
    artifacts: "./artifacts",
  },
  abiExporter: {
    path: "./abis",
    runOnCompile: true,
    clear: true,
    flat: true,
    pretty: false,
    except: ["test*"],
  },
  gasReporter: {
    enabled: !!process.env.REPORT_GAS,
    excludeContracts: ["test*"],
  },
};

export default config;
