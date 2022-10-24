import { ethers } from "hardhat";
import behavesLikeSeaportERC721OnlyUSDCOrders from "./shared-tests/behaves-like-seaport-erc721-only-usdc-orders";

describe("Seaport Order - ERC721 USDC Orders Non-atomic", () => {
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

  behavesLikeSeaportERC721OnlyUSDCOrders(false);
});
