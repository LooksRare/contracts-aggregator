import { ethers } from "hardhat";
import behavesLikeSeaportMultipleCurrenciesRandomOrderFees from "./shared-tests/behaves-like-seaport-multiple-currencies-random-order-fees";

describe("Seaport Order - Multiple Currencies Random Order With Fees Atomic", () => {
  before(async () => {
    await ethers.provider.send("hardhat_reset", [
      {
        forking: {
          jsonRpcUrl: process.env.ETH_RPC_URL,
          blockNumber: 15491323,
        },
      },
    ]);
  });

  behavesLikeSeaportMultipleCurrenciesRandomOrderFees(true);
});
