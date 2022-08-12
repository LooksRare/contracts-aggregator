import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { ethers } from "hardhat";
import { IERC721, LooksRareAggregator } from "../../../typechain";
import { BAYC } from "../../constants";

interface X2Y2Fixture {
  aggregator: LooksRareAggregator;
  buyer: SignerWithAddress;
  bayc: IERC721;
}

export default async function deployX2Y2Fixture(): Promise<X2Y2Fixture> {
  const Aggregator = await ethers.getContractFactory("LooksRareAggregator");
  const aggregator = await Aggregator.deploy();
  await aggregator.deployed();

  const [buyer] = await ethers.getSigners();

  await ethers.provider.send("hardhat_setBalance", [
    buyer.address,
    ethers.utils.parseEther("200").toHexString().replace("0x0", "0x"),
  ]);

  const bayc = await ethers.getContractAt("IERC721", BAYC);

  return { aggregator, buyer, bayc };
}
