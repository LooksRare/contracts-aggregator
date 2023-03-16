import type { HardhatUserConfig } from "hardhat/types";
import { task } from "hardhat/config";

import "@nomiclabs/hardhat-etherscan";
import "@nomiclabs/hardhat-waffle";
import "@typechain/hardhat";
import "dotenv/config";
import "hardhat-abi-exporter";
import "hardhat-gas-reporter";
import "solidity-coverage";
import "solidity-docgen";

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
      hardfork: "berlin", // Berlin is used (temporarily) to avoid issues with coverage
      mining: {
        auto: true,
        interval: 50000,
      },
      gasPrice: "auto",
    },
    mainnet: {
      chainId: 1,
      url: "https://rpc.ankr.com/eth",
    },
    goerli: {
      chainId: 5,
      url: "https://rpc.ankr.com/eth_goerli",
    },
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_KEY,
  },
  solidity: {
    compilers: [
      {
        version: "0.8.17",
        settings: { optimizer: { enabled: true, runs: 888888 }, viaIR: true },
      },
    ],
  },
  docgen: { pages: "files" },
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
    except: ["test*", "IERC20$", "IERC721$", "IERC1155$", "IERC165$"],
  },
  gasReporter: {
    enabled: process.env.REPORT_GAS === "true",
    excludeContracts: ["test*"],
  },
};

export default config;
