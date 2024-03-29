import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { ethers } from "hardhat";
import { LooksRareAggregator, SudoswapProxy } from "../../../typechain";
import getSignature from "../utils/get-signature";
import { MOODIE, SUDOSWAP } from "../../constants";
import { Contract } from "ethers";

interface SudoswapFixture {
  aggregator: LooksRareAggregator;
  proxy: SudoswapProxy;
  buyer: SignerWithAddress;
  functionSelector: string;
  moodie: Contract;
}

export default async function deploySudoswapFixture(): Promise<SudoswapFixture> {
  const Aggregator = await ethers.getContractFactory("LooksRareAggregator");
  const accounts = await ethers.getSigners();
  const aggregator = await Aggregator.deploy(accounts[0].address);
  await aggregator.deployed();

  const SudoswapProxy = await ethers.getContractFactory("SudoswapProxy");
  const proxy = await SudoswapProxy.deploy(SUDOSWAP, aggregator.address);
  await proxy.deployed();

  const functionSelector = await getSignature("SudoswapProxy.json", "execute");
  await aggregator.addFunction(proxy.address, functionSelector);

  const [, , buyer] = await ethers.getSigners();

  await ethers.provider.send("hardhat_setBalance", [
    buyer.address,
    ethers.utils.parseEther("200").toHexString().replace("0x0", "0x"),
  ]);

  await ethers.provider.send("hardhat_setBalance", [aggregator.address, "0x1"]);

  const moodie = await ethers.getContractAt(
    "@looksrare/contracts-libs/contracts/interfaces/generic/IERC721.sol:IERC721",
    MOODIE
  );

  return { aggregator, proxy, buyer, functionSelector, moodie };
}
