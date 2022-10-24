import { ethers } from "hardhat";
import behavesLikeSeaportERC1155 from "./shared-tests/behaves-like-seaport-erc1155";

describe("Seaport Order - ERC1155 Atomic", () => {
  before(async () => {
    await ethers.provider.send("hardhat_reset", [
      {
        forking: {
          jsonRpcUrl: process.env.ETH_RPC_URL,
          blockNumber: 15320038,
        },
      },
    ]);
  });

  behavesLikeSeaportERC1155(true);
});
