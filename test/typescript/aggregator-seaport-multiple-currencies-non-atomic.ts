import { ethers } from "hardhat";
import behavesLikeSeaportMultipleCurrencies from "./shared-tests/behaves-like-seaport-multiple-currencies";

describe("Aggregator", () => {
  before(async () => {
    await ethers.provider.send("hardhat_reset", [
      {
        forking: {
          jsonRpcUrl: process.env.ETH_RPC_URL,
          blockNumber: 15447813,
        },
      },
    ]);
  });

  behavesLikeSeaportMultipleCurrencies(false);
});
