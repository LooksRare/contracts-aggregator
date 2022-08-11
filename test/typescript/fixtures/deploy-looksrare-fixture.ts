import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { ethers } from "hardhat";
import { IERC721, LooksRareAggregator, LooksRareV2Proxy } from "../../../typechain";
import getSignature from "../utils/get-signature";
import { BAYC } from "../../constants";

interface LooksRareFixture {
  aggregator: LooksRareAggregator;
  proxy: LooksRareV2Proxy;
  buyer: SignerWithAddress;
  functionSelector: string;
  bayc: IERC721;
}

export default async function deployLooksRareFixture(): Promise<LooksRareFixture> {
  const Aggregator = await ethers.getContractFactory("LooksRareAggregator");
  const aggregator = await Aggregator.deploy();
  await aggregator.deployed();

  const LooksRareV2Proxy = await ethers.getContractFactory("LooksRareV2Proxy");
  const proxy = await LooksRareV2Proxy.deploy();
  await proxy.deployed();

  const functionSelector = await getSignature("LooksRareV2Proxy.json", "buyWithETH");
  await aggregator.addFunction(proxy.address, functionSelector);

  const [buyer] = await ethers.getSigners();

  await ethers.provider.send("hardhat_setBalance", [
    buyer.address,
    ethers.utils.parseEther("200").toHexString().replace("0x0", "0x"),
  ]);

  const bayc = await ethers.getContractAt("IERC721", BAYC);

  return { aggregator, proxy, functionSelector, buyer, bayc };
}
