import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { ethers } from "hardhat";
import { IERC721, LooksRareAggregator, SudoswapProxy } from "../../../typechain";
import getSignature from "../utils/get-signature";
import { MOODIE, SUDOSWAP } from "../../constants";

interface SudoswapFixture {
  aggregator: LooksRareAggregator;
  proxy: SudoswapProxy;
  buyer: SignerWithAddress;
  functionSelector: string;
  moodie: IERC721;
}

export default async function deploySudoswapFixture(): Promise<SudoswapFixture> {
  const Aggregator = await ethers.getContractFactory("LooksRareAggregator");
  const aggregator = await Aggregator.deploy();
  await aggregator.deployed();

  const SudoswapProxy = await ethers.getContractFactory("SudoswapProxy");
  const proxy = await SudoswapProxy.deploy(SUDOSWAP);
  await proxy.deployed();

  const functionSelector = await getSignature("SudoswapProxy.json", "buyWithETH");
  await aggregator.addFunction(proxy.address, functionSelector);

  const [buyer] = await ethers.getSigners();

  await ethers.provider.send("hardhat_setBalance", [
    buyer.address,
    ethers.utils.parseEther("200").toHexString().replace("0x0", "0x"),
  ]);

  const moodie = await ethers.getContractAt("IERC721", MOODIE);

  return { aggregator, proxy, buyer, functionSelector, moodie };
}
